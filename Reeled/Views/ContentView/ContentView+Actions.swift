import AVFoundation
import Photos
import PhotosUI
import SwiftUI
import UIKit

extension ContentView {

    func loadAndProcess(item: PhotosPickerItem) {
        isProcessing = true
        if originalImage == nil { processedImage = nil }

        // Stop any existing video preview
        videoPreviewEngine?.stop()
        videoPreviewEngine = nil
        sourceVideoAsset = nil
        sourceVideoURL = nil

        let snap = settings.snapshot()
        printSettings(snap)

        // Check if the selected item is a video
        let isVideo = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) })

        if isVideo {
            Task {
                do {
                    let videoURL = try await loadVideoFile(from: item)
                    let asset = AVURLAsset(url: videoURL)

                    // Extract filename
                    var filename: String?
                    if let assetID = item.itemIdentifier {
                        let results = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
                        if let phAsset = results.firstObject {
                            let resources = PHAssetResource.assetResources(for: phAsset)
                            filename = resources.first?.originalFilename
                        }
                    }

                    // Extract first frame as originalImage
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.maximumSize = CGSize(width: 640, height: 640)
                    if let (cgImage, _) = try? await generator.image(at: .zero) {
                        let firstFrame = UIImage(cgImage: cgImage)
                        await MainActor.run {
                            originalFilename = filename
                            originalImage = firstFrame
                            sourceVideoAsset = asset
                            sourceVideoURL = videoURL
                        }

                        // Create and start preview engine
                        let engine = VideoPreviewEngine(settings: snap)
                        await MainActor.run {
                            videoPreviewEngine = engine
                            isProcessing = false
                        }
                        await engine.load(asset: asset)
                    } else {
                        await MainActor.run {
                            isProcessing = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        isProcessing = false
                        saveErrorMessage = error.localizedDescription
                        showingSaveError = true
                    }
                }
            }
        } else {
            Task.detached {
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else {
                    await MainActor.run {
                        isProcessing = false
                    }
                    return
                }

                // Extract original filename from PHAsset, or fall back to content type
                var filename: String?
                if let assetID = item.itemIdentifier {
                    let results = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
                    if let asset = results.firstObject {
                        let resources = PHAssetResource.assetResources(for: asset)
                        filename = resources.first?.originalFilename
                    }
                }

                await MainActor.run {
                    originalFilename = filename
                    originalImage = uiImage
                }

                let result = VHSFilter.apply(to: uiImage, settings: snap)

                await MainActor.run {
                    processedImage = result
                    isProcessing = false
                }
            }
        }
    }

    func loadVideoFile(from item: PhotosPickerItem) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")

        // Try to get video via PHAsset for better reliability
        if let assetID = item.itemIdentifier {
            let results = PHAsset.fetchAssets(withLocalIdentifiers: [assetID], options: nil)
            if let phAsset = results.firstObject, phAsset.mediaType == .video {
                return try await withCheckedThrowingContinuation { continuation in
                    let options = PHVideoRequestOptions()
                    options.version = .current
                    options.isNetworkAccessAllowed = true
                    PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, info in
                        if let urlAsset = avAsset as? AVURLAsset {
                            // Copy to temp location to ensure the URL stays valid
                            do {
                                try FileManager.default.copyItem(at: urlAsset.url, to: tempURL)
                                continuation.resume(returning: tempURL)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        } else if let error = info?[PHImageErrorKey] as? Error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(throwing: VideoLoadError.failedToLoadVideo)
                        }
                    }
                }
            }
        }

        // Fallback: load as data
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw VideoLoadError.failedToLoadVideo
        }
        try data.write(to: tempURL)
        return tempURL
    }

    enum VideoLoadError: LocalizedError {
        case failedToLoadVideo

        var errorDescription: String? {
            switch self {
            case .failedToLoadVideo: "Failed to load video."
            }
        }
    }

    func reprocess() {
        guard let originalImage, !isProcessing else { return }
        isProcessing = true
        let snap = settings.snapshot()
        printSettings(snap)

        Task.detached {
            let result = VHSFilter.apply(to: originalImage, settings: snap)
            await MainActor.run {
                processedImage = result
                isProcessing = false
            }
        }
    }

    func printSettings(_ snap: VHSFilterSettings.Snapshot) {
        #if DEBUG
        debugPrint("""
        [VHS Settings] \
        chromatic=\(snap.chromaticAberration) \
        sat=\(snap.saturation) \
        bright=\(snap.brightness) \
        contrast=\(snap.contrast) \
        warmth=\(snap.warmth) \
        soft=\(snap.softness) \
        sharp=\(snap.sharpness) \
        scanlines=\(snap.scanlineOpacity) \
        noise=\(snap.noiseLines) \
        disp=\(snap.displacement) \
        grain=\(snap.grain) \
        microDistortion=\(snap.microDistortion) \
        vignette=\(snap.vignette) \
        bloom=\(snap.bloom)
        """)
        #endif
    }

    func exportVideo() {
        guard let originalImage, !isExporting else {
            #if DEBUG
            debugPrint("[ContentView] exportVideo guard failed: originalImage=\(originalImage != nil), isExporting=\(isExporting)")
            #endif
            return
        }
        isExporting = true
        exportProgress = 0
        UIApplication.shared.isIdleTimerDisabled = true
        let snap = settings.snapshot()
        let videoURL = sourceVideoURL

        #if DEBUG
        debugPrint("[ContentView] exportVideo started, hasVideoURL=\(videoURL != nil)")
        #endif

        // Pause video preview during export
        videoPreviewEngine?.pause()

        Task.detached {
            do {
                let url: URL
                if let videoURL {
                    #if DEBUG
                    debugPrint("[ContentView] Calling exportFromVideo with URL: \(videoURL.lastPathComponent)")
                    #endif
                    let asset = AVURLAsset(url: videoURL)
                    url = try await VideoExporter.exportFromVideo(
                        asset: asset,
                        settings: snap
                    ) { value in
                        Task { @MainActor in
                            exportProgress = value
                        }
                    }
                } else {
                    #if DEBUG
                    debugPrint("[ContentView] Calling export (image mode)")
                    #endif
                    url = try await VideoExporter.export(
                        image: originalImage,
                        settings: snap
                    ) { value in
                        Task { @MainActor in
                            exportProgress = value
                        }
                    }
                }

                #if DEBUG
                debugPrint("[ContentView] Export returned URL: \(url.lastPathComponent), saving to photo library...")
                #endif
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }
                #if DEBUG
                debugPrint("[ContentView] Saved to photo library successfully")
                #endif

                try? FileManager.default.removeItem(at: url)

                await MainActor.run {
                    isExporting = false
                    UIApplication.shared.isIdleTimerDisabled = false
                    videoPreviewEngine?.play()
                    showDoneIndicator()
                    #if DEBUG
                    debugPrint("[ContentView] Export flow complete, UI reset")
                    #endif
                }
            } catch {
                #if DEBUG
                debugPrint("[ContentView] Export error: \(error)")
                #endif
                await MainActor.run {
                    isExporting = false
                    UIApplication.shared.isIdleTimerDisabled = false
                    videoPreviewEngine?.play()
                    saveErrorMessage = error.localizedDescription
                    showingSaveError = true
                }
            }
        }
    }

    func savePhoto() {
        guard let imageToSave = processedImage ?? videoPreviewEngine?.currentFrame else { return }
        let saver = ImageSaver {
            showDoneIndicator()
        } onError: { error in
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
        saver.save(image: imageToSave)
    }

    func showDoneIndicator() {
        showingDone = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            showingDone = false
        }
    }
}
