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

        #if DEBUG
        debugPrint("[export] Starting image export: \(totalFrames) frames")
        debugPrint("[export] Pre-rendering \(totalFrames) filtered frames...")
        #endif
        let renderStart = CFAbsoluteTimeGetCurrent()
        let renderedFrames: [CGImage] = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var frames: [CGImage] = []
                frames.reserveCapacity(totalFrames)
                for frame in 0..<totalFrames {
                    let rendered: CGImage? = autoreleasepool {
                        VHSFilter.apply(to: image, settings: settings)?.cgImage
                    }
                    guard let rendered else {
                        #if DEBUG
                        debugPrint("[export] VHSFilter.apply returned nil at frame \(frame)")
                        #endif
                        continuation.resume(throwing: ExportError.renderFailed)
                        return
                    }
                    frames.append(rendered)
                    progress(Double(frame + 1) / Double(totalFrames) * 0.8)
                    #if DEBUG
                    if frame % 30 == 0 {
                        debugPrint("[export] Pre-rendered \(frame + 1)/\(totalFrames)")
                    }
                    #endif
                }
                continuation.resume(returning: frames)
            }
        }
        #if DEBUG
        debugPrint("[export] Pre-render done in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - renderStart))s")
        #endif

        let width = renderedFrames[0].width
        let height = renderedFrames[0].height
        let videoURL = try await writeVideoFile(
            frames: renderedFrames, to: outputURL,
            width: width, height: height, tag: "export"
        ) { frame in
            progress(0.8 + Double(frame + 1) / Double(totalFrames) * 0.2)
        }

        let finalURL = try await muxVHSAudio(into: videoURL, duration: duration)
        #if DEBUG
        debugPrint("[export] Export complete: \(finalURL.lastPathComponent)")
        #endif
        return finalURL
    }

    // MARK: - Video Export (source video → filtered video with audio)

    static func exportFromVideo(
        asset: AVAsset,
        settings: VHSFilterSettings.Snapshot,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        #if DEBUG
        let exportStart = CFAbsoluteTimeGetCurrent()
        debugPrint("[exportVideo] Starting video export")
        #endif

        let info = try await loadVideoInfo(from: asset)
        let extractedFrames = try await extractFrames(from: asset, info: info)
        let renderedFrames = try await applyFilter(
            to: extractedFrames, totalFrames: info.totalFrames,
            settings: settings, progress: progress
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        let orderedFrames: [CGImage] = (0..<info.totalFrames).compactMap { renderedFrames[$0] }
        let videoURL = try await writeVideoFile(
            frames: orderedFrames, to: outputURL,
            width: info.vhsWidth, height: info.vhsHeight, tag: "exportVideo"
        ) { frame in
            progress(0.8 + Double(frame + 1) / Double(orderedFrames.count) * 0.15)
        }

        let finalURL = try await muxVideoAudio(
            videoURL: videoURL, originalAsset: asset
        )

        progress(1.0)
        #if DEBUG
        debugPrint("[exportVideo] Export complete in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - exportStart))s")
        #endif
        return finalURL
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

// MARK: - Video Info

private extension VideoExporter {

    struct VideoInfo {
        let totalFrames: Int
        let vhsWidth: Int
        let vhsHeight: Int
        let frameDuration: CMTime
    }

    static func loadVideoInfo(from asset: AVAsset) async throws -> VideoInfo {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            #if DEBUG
            debugPrint("[exportVideo] No video track found")
            #endif
            throw ExportError.renderFailed
        }
        let duration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(duration)
        let totalFrames = Int(ceil(totalSeconds * frameRate))
        guard totalFrames > 0 else {
            #if DEBUG
            debugPrint("[exportVideo] totalFrames is 0")
            #endif
            throw ExportError.renderFailed
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let sourceW = abs(transformedSize.width)
        let sourceH = abs(transformedSize.height)
        let isLandscape = sourceW >= sourceH

        #if DEBUG
        debugPrint("[exportVideo] Duration: \(String(format: "%.2f", totalSeconds))s, totalFrames: \(totalFrames)")
        debugPrint("[exportVideo] Source: \(String(format: "%.0f", sourceW))x\(String(format: "%.0f", sourceH))")
        #endif

        return VideoInfo(
            totalFrames: totalFrames,
            vhsWidth: isLandscape ? 640 : 480,
            vhsHeight: isLandscape ? 480 : 640,
            frameDuration: CMTime(value: 1000, timescale: CMTimeScale(frameRate * 1000))
        )
    }
}

// MARK: - Frame Extraction & Filtering

private extension VideoExporter {

    static func extractFrames(from asset: AVAsset, info: VideoInfo) async throws -> [Int: CGImage] {
        #if DEBUG
        debugPrint("[exportVideo] Phase 1: Extracting frames...")
        let extractionStart = CFAbsoluteTimeGetCurrent()
        #endif

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: info.vhsWidth, height: info.vhsHeight)
        generator.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 600)

        let frameTimes: [NSValue] = (0..<info.totalFrames).map { frame in
            NSValue(time: CMTimeMultiply(info.frameDuration, multiplier: Int32(frame)))
        }

        let extracted: [Int: CGImage] = try await withCheckedThrowingContinuation { continuation in
            nonisolated(unsafe) var frames: [Int: CGImage] = [:]
            nonisolated(unsafe) var index = 0
            nonisolated(unsafe) var failCount = 0
            let totalCount = info.totalFrames
            generator.generateCGImagesAsynchronously(forTimes: frameTimes) { _, cgImage, _, _, error in
                if let cgImage {
                    frames[index] = cgImage
                } else {
                    failCount += 1
                    #if DEBUG
                    if let error {
                        debugPrint("[exportVideo] Frame \(index) extraction failed: \(error.localizedDescription)")
                    }
                    #endif
                }
                index += 1
                #if DEBUG
                if index % 60 == 0 || index >= totalCount {
                    debugPrint("[exportVideo] Extracted \(index)/\(totalCount) (\(failCount) failed)")
                }
                #endif
                if index >= totalCount {
                    continuation.resume(returning: frames)
                }
            }
        }
        #if DEBUG
        debugPrint("[exportVideo] Extraction done in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - extractionStart))s")
        #endif
        return extracted
    }

    static func applyFilter(
        to extractedFrames: [Int: CGImage],
        totalFrames: Int,
        settings: VHSFilterSettings.Snapshot,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> [Int: CGImage] {
        #if DEBUG
        debugPrint("[exportVideo] Phase 2: Applying VHS filter to \(extractedFrames.count) frames...")
        let filterStart = CFAbsoluteTimeGetCurrent()
        #endif
        let rendered: [Int: CGImage] = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var result: [Int: CGImage] = [:]
                var processedCount = 0
                for frame in 0..<totalFrames {
                    guard let sourceImage = extractedFrames[frame] else { continue }
                    let filteredCG: CGImage? = autoreleasepool {
                        let uiImage = UIImage(cgImage: sourceImage)
                        return VHSFilter.apply(to: uiImage, settings: settings)?.cgImage
                    }
                    if let filteredCG {
                        result[frame] = filteredCG
                    }
                    processedCount += 1
                    progress(Double(processedCount) / Double(totalFrames) * 0.8)
                    #if DEBUG
                    if frame < 3 || frame % 30 == 0 {
                        debugPrint("[exportVideo] Filtered frame \(frame)/\(totalFrames)")
                    }
                    #endif
                }
                #if DEBUG
                debugPrint("[exportVideo] Filter done: \(result.count) frames rendered")
                #endif
                continuation.resume(returning: result)
            }
        }
        #if DEBUG
        debugPrint("[exportVideo] Phase 2 done in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - filterStart))s")
        #endif
        return rendered
    }
}

// MARK: - Video Writing

private extension VideoExporter {

    static func writeVideoFile(
        frames: [CGImage], to outputURL: URL,
        width: Int, height: Int, tag: String,
        frameProgress: @Sendable @escaping (Int) -> Void
    ) async throws -> URL {
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
            #if DEBUG
            debugPrint("[\(tag)] Writer failed to start: \(writer.error?.localizedDescription ?? "unknown")")
            #endif
            throw ExportError.writerFailed(writer.error)
        }
        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(value: 1000, timescale: CMTimeScale(frameRate * 1000))
        #if DEBUG
        debugPrint("[\(tag)] Writing \(frames.count) frames to video...")
        #endif
        try await writeFrames(
            frames, to: writerInput, adaptor: adaptor,
            width: width, height: height,
            frameDuration: frameDuration, tag: tag,
            frameProgress: frameProgress
        )

        await writer.finishWriting()
        if writer.status == .failed {
            #if DEBUG
            debugPrint("[\(tag)] Writer failed: \(writer.error?.localizedDescription ?? "unknown")")
            #endif
            throw ExportError.writerFailed(writer.error)
        }
        #if DEBUG
        debugPrint("[\(tag)] Video file written")
        #endif
        return outputURL
    }

    static func writeFrames(
        _ frames: [CGImage],
        to writerInput: AVAssetWriterInput,
        adaptor: AVAssetWriterInputPixelBufferAdaptor,
        width: Int, height: Int,
        frameDuration: CMTime, tag: String,
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
                        #if DEBUG
                        debugPrint("[\(tag)] All \(totalFrames) frames written to video")
                        #endif
                        if !didResume { didResume = true; continuation.resume() }
                        return
                    }

                    let frame = frameIndex
                    frameIndex += 1

                    let cgImage = frames[frame]
                    let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frame))

                    guard let pool = adaptor.pixelBufferPool else {
                        #if DEBUG
                        debugPrint("[\(tag)] Pixel buffer pool unavailable at frame \(frame)")
                        #endif
                        writerInput.markAsFinished()
                        if !didResume { didResume = true; continuation.resume(throwing: ExportError.poolUnavailable) }
                        return
                    }
                    var pixelBuffer: CVPixelBuffer?
                    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                    guard let buffer = pixelBuffer else {
                        #if DEBUG
                        debugPrint("[\(tag)] Failed to create pixel buffer at frame \(frame)")
                        #endif
                        writerInput.markAsFinished()
                        if !didResume { didResume = true; continuation.resume(throwing: ExportError.bufferCreationFailed) }
                        return
                    }

                    CVPixelBufferLockBaseAddress(buffer, [])
                    let ctx = CGContext(
                        data: CVPixelBufferGetBaseAddress(buffer),
                        width: width, height: height,
                        bitsPerComponent: 8,
                        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
                    )
                    ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
                    CVPixelBufferUnlockBaseAddress(buffer, [])

                    if !adaptor.append(buffer, withPresentationTime: presentationTime) {
                        #if DEBUG
                        debugPrint("[\(tag)] adaptor.append failed at frame \(frame)")
                        #endif
                    }

                    #if DEBUG
                    if frame % 30 == 0 || frame == totalFrames - 1 {
                        debugPrint("[\(tag)] Wrote frame \(frame + 1)/\(totalFrames)")
                    }
                    #endif
                    frameProgress(frame)
                }
            }
        }
    }
}

// MARK: - Audio Muxing

private extension VideoExporter {

    static func muxVHSAudio(into videoURL: URL, duration: Double) async throws -> URL {
        let vhsAudioURL = try VHSAudioGenerator.generate(duration: duration)
        defer { try? FileManager.default.removeItem(at: vhsAudioURL) }

        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: videoURL)

        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else {
            return videoURL
        }
        let videoDuration = try await videoAsset.load(.duration)
        let compVideoTrack = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid
        )
        try compVideoTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: videoDuration), of: videoTrack, at: .zero
        )

        let vhsAudioAsset = AVURLAsset(url: vhsAudioURL)
        if let vhsAudioTrack = try await vhsAudioAsset.loadTracks(withMediaType: .audio).first {
            let vhsDuration = min(videoDuration, try await vhsAudioAsset.load(.duration))
            let compAudioTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try compAudioTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: vhsDuration), of: vhsAudioTrack, at: .zero
            )
        }

        return try await exportComposition(composition, replacingOriginal: videoURL)
    }

    static func muxVideoAudio(videoURL: URL, originalAsset: AVAsset) async throws -> URL {
        #if DEBUG
        debugPrint("[exportVideo] Phase 4: Muxing audio...")
        let muxStart = CFAbsoluteTimeGetCurrent()
        #endif

        let composition = AVMutableComposition()
        let videoOnlyAsset = AVURLAsset(url: videoURL)

        guard let filteredVideoTrack = try await videoOnlyAsset.loadTracks(withMediaType: .video).first else {
            #if DEBUG
            debugPrint("[exportVideo] Could not load filtered video track for muxing")
            #endif
            return videoURL
        }
        let filteredDuration = try await videoOnlyAsset.load(.duration)
        let compVideoTrack = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid
        )
        try compVideoTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: filteredDuration), of: filteredVideoTrack, at: .zero
        )

        // Add original audio
        let audioTracks = try await originalAsset.loadTracks(withMediaType: .audio)
        if let audioTrack = audioTracks.first {
            let audioDuration = min(filteredDuration, try await originalAsset.load(.duration))
            let compAudioTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try compAudioTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration), of: audioTrack, at: .zero
            )
        }

        // Add VHS tape hum
        let vhsAudioURL = try VHSAudioGenerator.generate(duration: CMTimeGetSeconds(filteredDuration))
        let vhsAudioAsset = AVURLAsset(url: vhsAudioURL)
        if let vhsAudioTrack = try await vhsAudioAsset.loadTracks(withMediaType: .audio).first {
            let vhsDuration = min(filteredDuration, try await vhsAudioAsset.load(.duration))
            let compVHSTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try compVHSTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: vhsDuration), of: vhsAudioTrack, at: .zero
            )
        }
        try? FileManager.default.removeItem(at: vhsAudioURL)

        let result = try await exportComposition(composition, replacingOriginal: videoURL)
        #if DEBUG
        debugPrint("[exportVideo] Audio muxed in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - muxStart))s")
        #endif
        return result
    }

    static func exportComposition(_ composition: AVMutableComposition, replacingOriginal originalURL: URL) async throws -> URL {
        let muxedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            return originalURL
        }
        session.outputURL = muxedURL
        session.outputFileType = .mov
        await session.export()

        if session.status == .completed {
            try? FileManager.default.removeItem(at: originalURL)
            return muxedURL
        } else {
            #if DEBUG
            debugPrint("[mux] Failed: \(session.error?.localizedDescription ?? "unknown")")
            #endif
            try? FileManager.default.removeItem(at: muxedURL)
            return originalURL
        }
    }
}
