import AVFoundation

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

    static func exportComposition(
        _ composition: AVMutableComposition,
        replacingOriginal originalURL: URL
    ) async throws -> URL {
        let muxedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            return originalURL
        }

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
