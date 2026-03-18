import AVFoundation

extension VideoExporter {

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
