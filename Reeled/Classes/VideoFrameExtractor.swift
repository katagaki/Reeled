import AVFoundation
import UIKit

struct VideoFrameExtractor: Sendable {

    let asset: AVAsset
    let duration: CMTime
    let frameRate: Double
    let totalFrameCount: Int

    private let generator: AVAssetImageGenerator

    init(asset: AVAsset, precise: Bool = false) async throws {
        self.asset = asset

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw ExtractorError.noVideoTrack
        }

        self.duration = try await asset.load(.duration)
        self.frameRate = try await Double(videoTrack.load(.nominalFrameRate))

        let seconds = CMTimeGetSeconds(duration)
        self.totalFrameCount = Int(ceil(seconds * 29.97))

        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 640, height: 640)
        if precise {
            gen.requestedTimeToleranceBefore = .zero
            gen.requestedTimeToleranceAfter = .zero
        } else {
            gen.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 30)
            gen.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 30)
        }
        self.generator = gen
    }

    func frame(at index: Int) -> UIImage? {
        let time = CMTime(value: CMTimeValue(index) * 1000, timescale: CMTimeScale(29.97 * 1000))
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    enum ExtractorError: LocalizedError {
        case noVideoTrack

        var errorDescription: String? {
            switch self {
            case .noVideoTrack: "No video track found."
            }
        }
    }
}
