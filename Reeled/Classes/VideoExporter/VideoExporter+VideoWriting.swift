import AVFoundation
import CoreVideo

extension VideoExporter {

    // swiftlint:disable:next function_parameter_count
    static func writeVideoFile(
        frames: [CGImage],
        to outputURL: URL,
        width: Int,
        height: Int,
        tag: String,
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
            frames,
            to: writerInput,
            adaptor: adaptor,
            width: width,
            height: height,
            frameDuration: frameDuration,
            tag: tag,
            frameProgress: frameProgress
        )

        guard writer.status == .writing else {
            #if DEBUG
            debugPrint("[\(tag)] Writer not in writing state: \(writer.status.rawValue), error: \(writer.error?.localizedDescription ?? "none")")
            #endif
            throw ExportError.writerFailed(writer.error)
        }
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

    // swiftlint:disable:next function_parameter_count, function_body_length
    static func writeFrames(
        _ frames: [CGImage],
        to writerInput: AVAssetWriterInput,
        adaptor: AVAssetWriterInputPixelBufferAdaptor,
        width: Int, height: Int,
        frameDuration: CMTime, tag: String,
        frameProgress: @Sendable @escaping (Int) -> Void
    ) async throws {
        let totalFrames = frames.count

        for frame in 0..<totalFrames {
            // Wait until the writer input is ready for more data
            while !writerInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }

            let cgImage = frames[frame]
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frame))

            guard let pool = adaptor.pixelBufferPool else {
                #if DEBUG
                debugPrint("[\(tag)] Pixel buffer pool unavailable at frame \(frame)")
                #endif
                writerInput.markAsFinished()
                throw ExportError.poolUnavailable
            }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard let buffer = pixelBuffer else {
                #if DEBUG
                debugPrint("[\(tag)] Failed to create pixel buffer at frame \(frame)")
                #endif
                writerInput.markAsFinished()
                throw ExportError.bufferCreationFailed
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

        writerInput.markAsFinished()
        #if DEBUG
        debugPrint("[\(tag)] All \(totalFrames) frames written to video")
        #endif
    }
}
