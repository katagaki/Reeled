import AVFoundation
import Accelerate

extension VideoExporter {

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
        var hasOriginalAudio = false
        if let audioTrack = audioTracks.first {
            let audioDuration = min(filteredDuration, try await originalAsset.load(.duration))
            let compAudioTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try compAudioTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration), of: audioTrack, at: .zero
            )
            hasOriginalAudio = true
        }

        // Add VHS tape hum
        let durationSeconds = CMTimeGetSeconds(filteredDuration)
        let vhsAudioURL = try VHSAudioGenerator.generate(duration: durationSeconds)
        let vhsAudioAsset = AVURLAsset(url: vhsAudioURL)
        var compVHSTrack: AVMutableCompositionTrack?
        if let vhsAudioTrack = try await vhsAudioAsset.loadTracks(withMediaType: .audio).first {
            let vhsDuration = min(filteredDuration, try await vhsAudioAsset.load(.duration))
            compVHSTrack = composition.addMutableTrack(
                withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
            )
            try compVHSTrack?.insertTimeRange(
                CMTimeRange(start: .zero, duration: vhsDuration), of: vhsAudioTrack, at: .zero
            )
        }
        try? FileManager.default.removeItem(at: vhsAudioURL)

        // Build audio mix with ducking for VHS hum when original audio is present
        var audioMix: AVAudioMix?
        if hasOriginalAudio, let vhsTrack = compVHSTrack {
            let levels = try await analyzeAudioLevels(asset: originalAsset, duration: durationSeconds)
            audioMix = buildDuckingMix(for: vhsTrack, levels: levels, duration: durationSeconds)
        }

        let result = try await exportComposition(
            composition, replacingOriginal: videoURL, audioMix: audioMix
        )
        #if DEBUG
        debugPrint("[exportVideo] Audio muxed in \(String(format: "%.2f", CFAbsoluteTimeGetCurrent() - muxStart))s")
        #endif
        return result
    }

    // MARK: - Audio Level Analysis

    /// Analyzes the original audio and returns RMS levels per time window.
    private static func analyzeAudioLevels(
        asset: AVAsset,
        duration: Double,
        windowDuration: Double = 0.1
    ) async throws -> [Float] {
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            return []
        }

        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        reader.add(output)
        reader.startReading()

        let sampleRate = 44100.0
        let samplesPerWindow = Int(sampleRate * windowDuration)
        let windowCount = Int(ceil(duration / windowDuration))

        var levels = [Float](repeating: 0.0, count: windowCount)
        var allSamples = [Float]()
        allSamples.reserveCapacity(Int(duration * sampleRate))

        while let sampleBuffer = output.copyNextSampleBuffer() {
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil,
                                        totalLengthOut: &length, dataPointerOut: &dataPointer)
            guard let data = dataPointer else { continue }

            let audioDesc = CMSampleBufferGetFormatDescription(sampleBuffer)
            let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioDesc!)!.pointee
            let channelCount = Int(asbd.mChannelsPerFrame)
            let floatCount = length / MemoryLayout<Float>.size

            data.withMemoryRebound(to: Float.self, capacity: floatCount) { floats in
                if channelCount == 1 {
                    allSamples.append(contentsOf: UnsafeBufferPointer(start: floats, count: floatCount))
                } else {
                    // Mix down to mono by averaging channels
                    let frameCount = floatCount / channelCount
                    for frame in 0..<frameCount {
                        var sum: Float = 0
                        for ch in 0..<channelCount {
                            sum += floats[frame * channelCount + ch]
                        }
                        allSamples.append(sum / Float(channelCount))
                    }
                }
            }
        }

        // Compute RMS per window
        for window in 0..<windowCount {
            let start = window * samplesPerWindow
            let end = min(start + samplesPerWindow, allSamples.count)
            guard start < allSamples.count else { break }

            let count = end - start
            var sumOfSquares: Float = 0
            allSamples.withUnsafeBufferPointer { buffer in
                let slice = buffer.baseAddress! + start
                vDSP_svesq(slice, 1, &sumOfSquares, vDSP_Length(count))
            }
            levels[window] = sqrtf(sumOfSquares / Float(count))
        }

        return levels
    }

    // MARK: - Ducking Mix

    /// Builds an AVAudioMix that ducks the VHS hum based on original audio levels.
    /// The hum volume ranges from `maxVolume` (silence) down to `minVolume` (loud audio).
    private static func buildDuckingMix(
        for vhsTrack: AVMutableCompositionTrack,
        levels: [Float],
        duration: Double,
        windowDuration: Double = 0.1
    ) -> AVAudioMix {
        let maxVolume: Float = 1.0
        let minVolume: Float = 0.08

        let params = AVMutableAudioMixInputParameters(track: vhsTrack)

        if levels.isEmpty {
            params.setVolume(maxVolume, at: .zero)
        } else {
            // Find peak RMS level for normalization
            let peakRMS = levels.max() ?? 1.0
            let normalizer: Float = peakRMS > 0.001 ? 1.0 / peakRMS : 1.0

            for (index, rms) in levels.enumerated() {
                let time = CMTime(seconds: Double(index) * windowDuration, preferredTimescale: 600)
                // Normalize the RMS to 0...1 range, then compute ducking factor
                let normalizedLevel = min(rms * normalizer, 1.0)
                let volume = maxVolume - (maxVolume - minVolume) * normalizedLevel
                params.setVolume(volume, at: time)
            }
        }

        let mix = AVMutableAudioMix()
        mix.inputParameters = [params]
        return mix
    }

    // MARK: - Composition Export

    static func exportComposition(
        _ composition: AVMutableComposition,
        replacingOriginal originalURL: URL,
        audioMix: AVAudioMix? = nil
    ) async throws -> URL {
        let muxedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        let presetName = audioMix != nil
            ? AVAssetExportPresetHighestQuality
            : AVAssetExportPresetPassthrough
        guard let session = AVAssetExportSession(
            asset: composition, presetName: presetName
        ) else {
            return originalURL
        }
        session.audioMix = audioMix

        do {
            try await session.export(to: muxedURL, as: .mov)
            try? FileManager.default.removeItem(at: originalURL)
            return muxedURL
        } catch {
            #if DEBUG
            debugPrint("[mux] Failed: \(error.localizedDescription)")
            #endif
            try? FileManager.default.removeItem(at: muxedURL)
            return originalURL
        }
    }
}
