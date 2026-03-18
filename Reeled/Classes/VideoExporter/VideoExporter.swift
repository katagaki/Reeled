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
        var renderedFrames: [CGImage] = []
        renderedFrames.reserveCapacity(totalFrames)
        for frame in 0..<totalFrames {
            let rendered: CGImage? = autoreleasepool {
                VHSFilter.apply(to: image, settings: settings)?.cgImage
            }
            guard let rendered else {
                #if DEBUG
                debugPrint("[export] VHSFilter.apply returned nil at frame \(frame)")
                #endif
                throw ExportError.renderFailed
            }
            renderedFrames.append(rendered)
            progress(Double(frame + 1) / Double(totalFrames) * 0.8)
            #if DEBUG
            if frame % 30 == 0 {
                debugPrint("[export] Pre-rendered \(frame + 1)/\(totalFrames)")
            }
            #endif
            await Task.yield()
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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
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
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        // Set up image generator for one-at-a-time extraction
        nonisolated(unsafe) let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: info.vhsWidth, height: info.vhsHeight)
        generator.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 600)

        // Set up video writer
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: info.vhsWidth,
            AVVideoHeightKey: info.vhsHeight
        ])
        writerInput.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: info.vhsWidth,
                kCVPixelBufferHeightKey as String: info.vhsHeight
            ]
        )
        writer.add(writerInput)

        guard writer.startWriting() else {
            throw ExportError.writerFailed(writer.error)
        }
        writer.startSession(atSourceTime: .zero)

        // Stream: extract frame → filter → write, one at a time
        let totalFrames = info.totalFrames
        for frame in 0..<totalFrames {
            let requestTime = CMTimeMultiply(info.frameDuration, multiplier: Int32(frame))
            let presentationTime = requestTime

            // Extract
            let cgImage: CGImage
            do {
                let (image, _) = try await generator.image(at: requestTime)
                cgImage = image
            } catch {
                #if DEBUG
                debugPrint("[exportVideo] Frame \(frame) extraction failed: \(error.localizedDescription)")
                #endif
                continue
            }

            // Filter
            let filtered: CGImage? = autoreleasepool {
                let uiImage = UIImage(cgImage: cgImage)
                return VHSFilter.apply(to: uiImage, settings: settings)?.cgImage
            }
            guard let filteredCG = filtered else {
                #if DEBUG
                debugPrint("[exportVideo] Filter returned nil at frame \(frame)")
                #endif
                continue
            }

            // Write
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            guard let pool = adaptor.pixelBufferPool else {
                writerInput.markAsFinished()
                throw ExportError.poolUnavailable
            }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard let buffer = pixelBuffer else {
                writerInput.markAsFinished()
                throw ExportError.bufferCreationFailed
            }

            CVPixelBufferLockBaseAddress(buffer, [])
            let ctx = CGContext(
                data: CVPixelBufferGetBaseAddress(buffer),
                width: info.vhsWidth, height: info.vhsHeight,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            )
            ctx?.draw(filteredCG, in: CGRect(x: 0, y: 0, width: info.vhsWidth, height: info.vhsHeight))
            CVPixelBufferUnlockBaseAddress(buffer, [])

            if !adaptor.append(buffer, withPresentationTime: presentationTime) {
                #if DEBUG
                debugPrint("[exportVideo] adaptor.append failed at frame \(frame)")
                #endif
            }

            progress(Double(frame + 1) / Double(totalFrames) * 0.9)
            #if DEBUG
            if frame % 30 == 0 || frame == totalFrames - 1 {
                debugPrint("[exportVideo] Processed frame \(frame + 1)/\(totalFrames)")
            }
            #endif
        }

        writerInput.markAsFinished()

        guard writer.status == .writing else {
            throw ExportError.writerFailed(writer.error)
        }
        await writer.finishWriting()
        if writer.status == .failed {
            throw ExportError.writerFailed(writer.error)
        }

        // Mux audio
        let finalURL = try await muxVideoAudio(
            videoURL: outputURL, originalAsset: asset
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
