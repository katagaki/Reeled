import AVFoundation
import CoreImage
import UIKit

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
