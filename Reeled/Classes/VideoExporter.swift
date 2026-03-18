import AVFoundation
import CoreImage
import UIKit

struct VideoExporter: Sendable {

    static let frameRate: Double = 29.97
    static let duration: Double = 6.0

    static func export(
        image: UIImage,
        settings: VHSFilterSettings.Snapshot,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        let totalFrames = Int(ceil(frameRate * duration))
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        // Render first frame to determine output dimensions
        guard let firstFrame = VHSFilter.apply(to: image, settings: settings),
              let firstCG = firstFrame.cgImage else {
            throw ExportError.renderFailed
        }
        let width = firstCG.width
        let height = firstCG.height

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writerInput.expectsMediaDataInRealTime = false

        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: attrs
        )

        writer.add(writerInput)
        guard writer.startWriting() else {
            throw ExportError.writerFailed(writer.error)
        }
        writer.startSession(atSourceTime: .zero)

        let frameDuration = CMTime(value: 1000, timescale: CMTimeScale(frameRate * 1000))

        for frame in 0..<totalFrames {
            // Wait for the input to be ready
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(for: .milliseconds(10))
            }

            try Task.checkCancellation()

            let rendered = VHSFilter.apply(to: image, settings: settings)
            guard let cgImage = rendered?.cgImage else {
                throw ExportError.renderFailed
            }

            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frame))

            guard let pool = adaptor.pixelBufferPool else {
                throw ExportError.poolUnavailable
            }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard let buffer = pixelBuffer else {
                throw ExportError.bufferCreationFailed
            }

            CVPixelBufferLockBaseAddress(buffer, [])
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(buffer),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
            )
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            CVPixelBufferUnlockBaseAddress(buffer, [])

            adaptor.append(buffer, withPresentationTime: presentationTime)

            progress(Double(frame + 1) / Double(totalFrames))
            await Task.yield()
        }

        writerInput.markAsFinished()
        await writer.finishWriting()

        if writer.status == .failed {
            throw ExportError.writerFailed(writer.error)
        }

        return outputURL
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
