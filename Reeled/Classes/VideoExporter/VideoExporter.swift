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
