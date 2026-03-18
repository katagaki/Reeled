import AVFoundation
import Observation
import QuartzCore
import UIKit

@Observable
final class VideoPreviewEngine: @unchecked Sendable {

    private(set) var currentFrame: UIImage?
    private(set) var isPlaying: Bool = false

    private var extractor: VideoFrameExtractor?
    private var settings: VHSFilterSettings.Snapshot
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    private var pausedElapsed: CFTimeInterval = 0
    private var isRendering = false
    private let renderQueue = DispatchQueue(label: "com.reeled.preview", qos: .userInteractive)

    init(settings: VHSFilterSettings.Snapshot) {
        self.settings = settings
    }

    func load(asset: AVAsset) async {
        stop()
        do {
            let ext = try await VideoFrameExtractor(asset: asset)
            self.extractor = ext
            // Show first filtered frame immediately
            if let first = await ext.frame(at: 0) {
                let snap = settings
                let filtered = await Task.detached {
                    VHSFilter.apply(to: first, settings: snap)
                }.value
                await MainActor.run {
                    self.currentFrame = filtered
                }
            }
            await MainActor.run {
                play()
            }
        } catch {
            // Could not load video frames
        }
    }

    @MainActor
    func play() {
        guard extractor != nil, !isPlaying else { return }
        isPlaying = true
        let link = CADisplayLink(target: DisplayLinkTarget(engine: self), selector: #selector(DisplayLinkTarget.tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 24, maximum: 30, preferred: 30)
        link.add(to: .main, forMode: .common)
        displayLink = link
        startTime = CACurrentMediaTime() - pausedElapsed
    }

    @MainActor
    func pause() {
        guard isPlaying else { return }
        pausedElapsed = CACurrentMediaTime() - startTime
        displayLink?.invalidate()
        displayLink = nil
        isPlaying = false
    }

    func updateSettings(_ newSettings: VHSFilterSettings.Snapshot) {
        settings = newSettings
    }

    @MainActor
    func restart() {
        pausedElapsed = 0
        if isPlaying {
            startTime = CACurrentMediaTime()
        }
        // Show the first frame immediately
        guard let extractor else { return }
        let snap = settings
        Task.detached { [weak self] in
            guard let self else { return }
            if let first = await extractor.frame(at: 0) {
                let filtered = VHSFilter.apply(to: first, settings: snap)
                await MainActor.run {
                    self.currentFrame = filtered
                }
            }
        }
    }

    @MainActor
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isPlaying = false
        extractor = nil
        currentFrame = nil
        pausedElapsed = 0
        isRendering = false
    }

    fileprivate func onDisplayLinkTick() {
        guard let extractor, !isRendering else { return }

        let elapsed = CACurrentMediaTime() - startTime
        let videoDuration = CMTimeGetSeconds(extractor.duration)
        guard videoDuration > 0 else { return }

        let loopedTime = elapsed.truncatingRemainder(dividingBy: videoDuration)
        let frameIndex = Int(loopedTime * 29.97) % extractor.totalFrameCount

        isRendering = true
        let snap = settings

        Task.detached { [weak self] in
            guard let self else { return }
            guard let sourceFrame = await extractor.frame(at: frameIndex) else {
                await MainActor.run { self.isRendering = false }
                return
            }
            let filtered = VHSFilter.apply(to: sourceFrame, settings: snap)
            await MainActor.run {
                self.currentFrame = filtered
                self.isRendering = false
            }
        }
    }
}

// CADisplayLink requires an NSObject target
private class DisplayLinkTarget: NSObject {
    weak var engine: VideoPreviewEngine?

    init(engine: VideoPreviewEngine) {
        self.engine = engine
    }

    @objc func tick() {
        engine?.onDisplayLinkTick()
    }
}
