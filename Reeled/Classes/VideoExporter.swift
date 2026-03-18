import AVFoundation
import CoreImage
import UIKit

struct VideoExporter: Sendable {

    static let frameRate: Double = 29.97
    static let duration: Double = 6.0

    // MARK: - Image Export (static image → looping video)

    static func export(
        image: UIImage,
        settings: VHSFilterSettings.Snapshot,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        let totalFrames = Int(ceil(frameRate * duration))
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        debugPrint("[export] Starting image export: \(totalFrames) frames")

        // Pre-render all filtered frames on a background queue
        debugPrint("[export] Pre-rendering \(totalFrames) filtered frames...")
        let renderStart = CFAbsoluteTimeGetCurrent()
        let renderedFrames: [CGImage] = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var frames: [CGImage] = []
                frames.reserveCapacity(totalFrames)
                for i in 0..<totalFrames {
                    let rendered: CGImage? = autoreleasepool {
                        VHSFilter.apply(to: image, settings: settings)?.cgImage
                    }
                    guard let rendered else {
                        debugPrint("[export] VHSFilter.apply returned nil at frame \(i)")
                        continuation.resume(throwing: ExportError.renderFailed)
                        return
                    }
                    frames.append(rendered)
                    progress(Double(i + 1) / Double(totalFrames) * 0.8)
                    if i % 30 == 0 {
                        debugPrint("[export] Pre-rendered \(i + 1)/\(totalFrames)")
                    }
                }
                continuation.resume(returning: frames)
            }
        }
        debugPrint("[export] Pre-render done in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - renderStart))s")

        let width = renderedFrames[0].width
        let height = renderedFrames[0].height

        // Write all pre-rendered frames
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ])
        writerInput.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )
        writer.add(writerInput)

        guard writer.startWriting() else {
            debugPrint("[export] Writer failed to start: \(writer.error?.localizedDescription ?? "unknown")")
            throw ExportError.writerFailed(writer.error)
        }
        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(value: 1000, timescale: CMTimeScale(frameRate * 1000))

        debugPrint("[export] Writing \(renderedFrames.count) frames to video...")
        try await writeFrames(
            renderedFrames,
            to: writerInput,
            adaptor: adaptor,
            width: width,
            height: height,
            frameDuration: frameDuration,
            tag: "export"
        ) { frame in
            progress(0.8 + Double(frame + 1) / Double(totalFrames) * 0.2)
        }

        await writer.finishWriting()
        if writer.status == .failed {
            debugPrint("[export] Writer failed: \(writer.error?.localizedDescription ?? "unknown")")
            throw ExportError.writerFailed(writer.error)
        }
        debugPrint("[export] Export complete: \(outputURL.lastPathComponent)")
        return outputURL
    }

    // MARK: - Video Export (source video → filtered video with audio)

    static func exportFromVideo(
        asset: AVAsset,
        settings: VHSFilterSettings.Snapshot,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        let exportStart = CFAbsoluteTimeGetCurrent()
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        debugPrint("[exportVideo] Starting video export")

        // Load video track info
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            debugPrint("[exportVideo] No video track found")
            throw ExportError.renderFailed
        }
        let duration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(duration)
        let totalFrames = Int(ceil(totalSeconds * frameRate))
        guard totalFrames > 0 else {
            debugPrint("[exportVideo] totalFrames is 0")
            throw ExportError.renderFailed
        }
        debugPrint("[exportVideo] Duration: \(String(format: "%.2f", totalSeconds))s, totalFrames: \(totalFrames)")

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let sourceW = abs(transformedSize.width)
        let sourceH = abs(transformedSize.height)
        let isLandscape = sourceW >= sourceH
        let vhsW = isLandscape ? 640 : 480
        let vhsH = isLandscape ? 480 : 640
        debugPrint("[exportVideo] Source: \(String(format: "%.0f", sourceW))x\(String(format: "%.0f", sourceH)) → \(vhsW)x\(vhsH)")

        // Phase 1: Extract source frames
        debugPrint("[exportVideo] Phase 1: Extracting frames...")
        let extractionStart = CFAbsoluteTimeGetCurrent()
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: vhsW, height: vhsH)
        generator.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 600)

        let frameDuration = CMTime(value: 1000, timescale: CMTimeScale(frameRate * 1000))
        let frameTimes: [NSValue] = (0..<totalFrames).map { frame in
            NSValue(time: CMTimeMultiply(frameDuration, multiplier: Int32(frame)))
        }

        let extractedFrames: [Int: CGImage] = try await withCheckedThrowingContinuation { continuation in
            nonisolated(unsafe) var frames: [Int: CGImage] = [:]
            nonisolated(unsafe) var index = 0
            nonisolated(unsafe) var failCount = 0
            let totalCount = totalFrames
            generator.generateCGImagesAsynchronously(forTimes: frameTimes) { _, cgImage, _, _, error in
                if let cgImage {
                    frames[index] = cgImage
                } else {
                    failCount += 1
                    if let error {
                        debugPrint("[exportVideo] Frame \(index) extraction failed: \(error.localizedDescription)")
                    }
                }
                index += 1
                if index % 60 == 0 || index >= totalCount {
                    debugPrint("[exportVideo] Extracted \(index)/\(totalCount) (\(failCount) failed)")
                }
                if index >= totalCount {
                    continuation.resume(returning: frames)
                }
            }
        }
        debugPrint("[exportVideo] Extraction done in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - extractionStart))s, got \(extractedFrames.count)/\(totalFrames) frames")

        // Phase 2: Apply VHS filter to all frames on a background queue
        debugPrint("[exportVideo] Phase 2: Applying VHS filter to \(extractedFrames.count) frames...")
        let filterStart = CFAbsoluteTimeGetCurrent()
        let renderedFrames: [Int: CGImage] = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var rendered: [Int: CGImage] = [:]
                var processedCount = 0
                for frame in 0..<totalFrames {
                    guard let sourceImage = extractedFrames[frame] else { continue }
                    let filteredCG: CGImage? = autoreleasepool {
                        let uiImage = UIImage(cgImage: sourceImage)
                        return VHSFilter.apply(to: uiImage, settings: settings)?.cgImage
                    }
                    if let filteredCG {
                        rendered[frame] = filteredCG
                    }
                    processedCount += 1
                    progress(Double(processedCount) / Double(totalFrames) * 0.8)
                    if frame < 3 || frame % 30 == 0 {
                        debugPrint("[exportVideo] Filtered frame \(frame)/\(totalFrames)")
                    }
                }
                debugPrint("[exportVideo] Filter done: \(rendered.count) frames rendered")
                continuation.resume(returning: rendered)
            }
        }
        let filterElapsed = CFAbsoluteTimeGetCurrent() - filterStart
        debugPrint("[exportVideo] Phase 2 done in \(String(format: "%.2f", filterElapsed))s")

        // Phase 3: Write video
        debugPrint("[exportVideo] Phase 3: Writing video...")
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: vhsW,
            AVVideoHeightKey: vhsH
        ])
        writerInput.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: vhsW,
                kCVPixelBufferHeightKey as String: vhsH
            ]
        )
        writer.add(writerInput)

        // Write video only — no audio input added, so the writer won't stall
        // waiting for interleaved audio data.
        guard writer.startWriting() else {
            debugPrint("[exportVideo] Writer failed to start: \(writer.error?.localizedDescription ?? "unknown")")
            throw ExportError.writerFailed(writer.error)
        }
        writer.startSession(atSourceTime: .zero)
        debugPrint("[exportVideo] Writer started (video-only), status: \(writer.status.rawValue)")

        let orderedFrames: [CGImage] = (0..<totalFrames).compactMap { renderedFrames[$0] }
        debugPrint("[exportVideo] Writing \(orderedFrames.count) video frames...")

        try await writeFrames(
            orderedFrames,
            to: writerInput,
            adaptor: adaptor,
            width: vhsW,
            height: vhsH,
            frameDuration: frameDuration,
            tag: "exportVideo"
        ) { frame in
            progress(0.8 + Double(frame + 1) / Double(orderedFrames.count) * 0.15)
        }

        debugPrint("[exportVideo] Finishing video writer...")
        await writer.finishWriting()
        if writer.status == .failed {
            debugPrint("[exportVideo] Video writer failed: \(writer.error?.localizedDescription ?? "unknown")")
            throw ExportError.writerFailed(writer.error)
        }
        debugPrint("[exportVideo] Video-only file written")

        // Phase 4: Mux audio from original asset into the video-only file
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let finalURL: URL
        if let audioTrack = audioTracks.first {
            debugPrint("[exportVideo] Phase 4: Muxing audio...")
            let muxStart = CFAbsoluteTimeGetCurrent()

            let composition = AVMutableComposition()
            let videoOnlyAsset = AVURLAsset(url: outputURL)

            // Add the filtered video track
            guard let filteredVideoTrack = try await videoOnlyAsset.loadTracks(withMediaType: .video).first else {
                debugPrint("[exportVideo] Could not load filtered video track for muxing")
                return outputURL
            }
            let filteredDuration = try await videoOnlyAsset.load(.duration)
            let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: filteredDuration), of: filteredVideoTrack, at: .zero)

            // Add audio from original, trimmed to video duration
            let audioDuration = min(filteredDuration, try await asset.load(.duration))
            let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration), of: audioTrack, at: .zero)

            // Export the composition with re-encoded audio
            let muxedURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")

            guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
                debugPrint("[exportVideo] Could not create export session for muxing")
                return outputURL
            }
            exportSession.outputURL = muxedURL
            exportSession.outputFileType = .mov

            await exportSession.export()

            if exportSession.status == .completed {
                // Clean up the video-only temp file, use the muxed one
                try? FileManager.default.removeItem(at: outputURL)
                finalURL = muxedURL
                debugPrint("[exportVideo] Audio muxed in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - muxStart))s")
            } else {
                debugPrint("[exportVideo] Mux failed: \(exportSession.error?.localizedDescription ?? "unknown"), using video-only")
                try? FileManager.default.removeItem(at: muxedURL)
                finalURL = outputURL
            }
        } else {
            debugPrint("[exportVideo] No audio track to mux")
            finalURL = outputURL
        }

        progress(1.0)
        let totalElapsed = CFAbsoluteTimeGetCurrent() - exportStart
        debugPrint("[exportVideo] Export complete in \(String(format: "%.2f", totalElapsed))s")
        return finalURL
    }

    // MARK: - Shared frame writing

    /// Writes pre-rendered CGImage frames to an AVAssetWriterInput using requestMediaDataWhenReady.
    /// The callback only does lightweight pixel buffer copies — no heavy filter work.
    private static func writeFrames(
        _ frames: [CGImage],
        to writerInput: AVAssetWriterInput,
        adaptor: AVAssetWriterInputPixelBufferAdaptor,
        width: Int,
        height: Int,
        frameDuration: CMTime,
        tag: String,
        frameProgress: @Sendable @escaping (Int) -> Void
    ) async throws {
        let writeQueue = DispatchQueue(label: "com.reeled.\(tag).write", qos: .userInitiated)
        let totalFrames = frames.count

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            nonisolated(unsafe) var frameIndex = 0
            nonisolated(unsafe) var didResume = false

            writerInput.requestMediaDataWhenReady(on: writeQueue) {
                while writerInput.isReadyForMoreMediaData {
                    guard frameIndex < totalFrames else {
                        writerInput.markAsFinished()
                        debugPrint("[\(tag)] All \(totalFrames) frames written to video")
                        if !didResume { didResume = true; continuation.resume() }
                        return
                    }

                    let frame = frameIndex
                    frameIndex += 1

                    let cgImage = frames[frame]
                    let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frame))

                    guard let pool = adaptor.pixelBufferPool else {
                        debugPrint("[\(tag)] Pixel buffer pool unavailable at frame \(frame)")
                        writerInput.markAsFinished()
                        if !didResume { didResume = true; continuation.resume(throwing: ExportError.poolUnavailable) }
                        return
                    }
                    var pixelBuffer: CVPixelBuffer?
                    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                    guard let buffer = pixelBuffer else {
                        debugPrint("[\(tag)] Failed to create pixel buffer at frame \(frame)")
                        writerInput.markAsFinished()
                        if !didResume { didResume = true; continuation.resume(throwing: ExportError.bufferCreationFailed) }
                        return
                    }

                    CVPixelBufferLockBaseAddress(buffer, [])
                    let ctx = CGContext(
                        data: CVPixelBufferGetBaseAddress(buffer),
                        width: width,
                        height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                    )
                    ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                    CVPixelBufferUnlockBaseAddress(buffer, [])

                    if !adaptor.append(buffer, withPresentationTime: presentationTime) {
                        debugPrint("[\(tag)] adaptor.append failed at frame \(frame)")
                    }

                    if frame % 30 == 0 || frame == totalFrames - 1 {
                        debugPrint("[\(tag)] Wrote frame \(frame + 1)/\(totalFrames)")
                    }
                    frameProgress(frame)
                }
            }
        }
    }

    enum ExportError: LocalizedError {
        case renderFailed
        case writerFailed(Error?)
        case poolUnavailable
        case bufferCreationFailed

        var errorDescription: String? {
            switch self {
            case .renderFailed: "Failed to render frame."
            case .writerFailed(let err): "Video writer failed: \(err?.localizedDescription ?? "unknown")"
            case .poolUnavailable: "Pixel buffer pool unavailable."
            case .bufferCreationFailed: "Failed to create pixel buffer."
            }
        }
    }
}
