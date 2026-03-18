import AVFoundation
import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {

    @Environment(\.theme) private var theme
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var settings = VHSFilterSettings()
    @State private var debounceTask: Task<Void, Never>?
    @State private var originalFilename: String?
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var showingDone = false
    @State private var sourceVideoAsset: AVAsset?
    @State private var sourceVideoURL: URL?
    @State private var videoPreviewEngine: VideoPreviewEngine?
    @State private var activeDragCount: Int = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.backgroundTop,
                    theme.backgroundMid,
                    theme.backgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 0)
                    .background(
                        ZStack {
                            LinearGradient(
                                colors: [
                                    theme.headerTop,
                                    theme.headerMid,
                                    theme.headerBottom
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            LinearGradient(
                                colors: [
                                    theme.headerHighlightTop,
                                    theme.headerHighlightMid,
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        }
                        .ignoresSafeArea(edges: .top)
                    )
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(theme.headerDividerBottom)
                            .frame(height: 1)
                    }

                GeometryReader { geo in
                    let imageHeight = geo.size.height * 0.5
                    let slidersHeight = geo.size.height * 0.5

                    if processedImage == nil && videoPreviewEngine == nil && !isProcessing && !isExporting {
                        EmptyStateView()
                    } else {
                        VStack(spacing: 0) {
                            Group {
                                if let videoPreviewEngine {
                                    FilteredVideoPreviewView(engine: videoPreviewEngine)
                                } else if let processedImage {
                                    ProcessedImageView(image: processedImage)
                                } else {
                                    Spacer()
                                }
                            }
                            .frame(height: imageHeight)
                            .clipped()

                            if isExporting {
                                VStack(spacing: 0) {
                                    Spacer()
                                    ExportingTapeView(progress: exportProgress, filename: originalFilename)
                                    Spacer()
                                }
                                .frame(height: slidersHeight)
                            } else {
                                ScrollView {
                                    if processedImage != nil || videoPreviewEngine != nil || isProcessing {
                                        inlineSettingsPanel
                                    }
                                }
                                .frame(height: slidersHeight)
                            }
                        }
                    }
                }

                controlBar
            }
        }
        .onAppear {
            settings.load()
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            loadAndProcess(item: newItem)
        }
        .onChange(of: settings.version) { _, _ in
            guard originalImage != nil else { return }
            settings.save()
            if videoPreviewEngine != nil {
                videoPreviewEngine?.updateSettings(settings.snapshot())
            } else {
                debounceTask?.cancel()
                debounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    reprocess()
                }
            }
        }
        .alert(String(localized: "Alert.Error.Title"), isPresented: $showingSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var inlineSettingsPanel: some View {
        let dragHandler: (Bool) -> Void = { isDragging in
            activeDragCount += isDragging ? 1 : -1
            if let engine = videoPreviewEngine {
                if activeDragCount > 0 {
                    engine.pause()
                } else {
                    engine.updateSettings(settings.snapshot())
                    engine.play()
                }
            }
        }

        return VStack(spacing: 16) {
            Spacer().frame(height: 0)

            settingsGroup("COLOR") {
                VintageSlider(label: "SATURATION", value: $settings.saturation, range: 0...1.5, onDragChanged: dragHandler)
                VintageSlider(label: "BRIGHTNESS", value: $settings.brightness, range: -0.2...0.2, onDragChanged: dragHandler)
                VintageSlider(label: "CONTRAST", value: $settings.contrast, range: 0.5...1.5, onDragChanged: dragHandler)
                VintageSlider(label: "WARMTH", value: $settings.warmth, range: 4000...7000, onDragChanged: dragHandler)
            }

            settingsGroup("TEXTURE") {
                VintageSlider(label: "SOFTNESS", value: $settings.softness, range: 0...2, onDragChanged: dragHandler)
                VintageSlider(label: "SHARPNESS", value: $settings.sharpness, range: 0...2, onDragChanged: dragHandler)
                VintageSlider(label: "SCANLINES", value: $settings.scanlineOpacity, range: 0...0.2, onDragChanged: dragHandler)
                VintageSlider(label: "NOISE LINES", value: $settings.noiseLines, range: 0...10, onDragChanged: dragHandler)
                VintageSlider(label: "DISPLACEMENT", value: $settings.displacement, range: 0...8, onDragChanged: dragHandler)
                VintageSlider(label: "GRAIN", value: $settings.grain, range: 0...0.5, onDragChanged: dragHandler)
                VintageSlider(label: "MICRO DISTORTION", value: $settings.microDistortion, range: 0...1.0, onDragChanged: dragHandler)
            }

            settingsGroup("ATMOSPHERE") {
                VintageSlider(label: "VIGNETTE", value: $settings.vignette, range: 0...1.0, onDragChanged: dragHandler)
                VintageSlider(label: "BLOOM", value: $settings.bloom, range: 0...0.3, onDragChanged: dragHandler)
                VintageSlider(label: "CHROMATIC ABERRATION", value: $settings.chromaticAberration, range: 0...4, onDragChanged: dragHandler)
            }

            Spacer().frame(height: 0)
        }
    }

    @ViewBuilder
    private func settingsGroup(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("VCR-JP", size: 11))
                .foregroundStyle(theme.settingsGroupTitle)
                .padding(.leading, 4)

            VStack(spacing: 14) {
                content()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.settingsGroupBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        theme.settingsGroupBorderTop,
                                        theme.settingsGroupBorderBottom
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
            )
        }
        .padding(.horizontal, 16)
    }

    private var lcdText: String {
        if showingDone {
            return "SAVED"
        } else if isExporting {
            let pct = Int(exportProgress * 100)
            let suffix = "\(pct)%"
            let prefix = "EXPORTING"
            let spaces = String(repeating: " ", count: max(1, 16 - prefix.count - suffix.count))
            return "\(prefix)\(spaces)\(suffix)"
        } else if isProcessing {
            return "DUBBING"
        } else if originalImage == nil {
            return "INSERT PHOTO OR VIDEO"
        } else {
            return "READY"
        }
    }

    private var lcdScrolling: Bool {
        if showingDone || isExporting || isProcessing {
            return false
        }
        return originalImage == nil
    }

    private var controlBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(theme.controlBarTopEdge)
                .frame(height: 0.5)
            Rectangle()
                .fill(theme.controlBarBottomEdge)
                .frame(height: 0.5)

            LCDPanelView(text: lcdText, scrolling: lcdScrolling)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Insert"), systemImage: "eject.fill", tint: .blue))
                .disabled(isExporting)

                Button {
                    settings.resetToDefaults()
                } label: {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Reset"), systemImage: "arrow.uturn.backward", tint: .red))
                .disabled(originalImage == nil || isExporting)

                Button {
                    if videoPreviewEngine != nil {
                        videoPreviewEngine?.restart()
                    } else {
                        reprocess()
                    }
                } label: {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Rewind"), systemImage: "backward.end.fill", tint: .gray))
                .disabled(originalImage == nil || isProcessing || isExporting)

                Button {
                    exportVideo()
                } label: {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Video"), systemImage: "film.stack", tint: .orange))
                .disabled(originalImage == nil || isProcessing || isExporting)

                Button {
                    savePhoto()
                } label: {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Image"), systemImage: "photo", tint: .orange))
                .disabled((processedImage == nil && videoPreviewEngine == nil) || isProcessing || isExporting)
            }
            .padding(.vertical, 14)
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        theme.controlBarTop,
                        theme.controlBarMid,
                        theme.controlBarBottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    colors: [
                        theme.controlBarHighlight,
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func loadAndProcess(item: PhotosPickerItem) {
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

    private func loadVideoFile(from item: PhotosPickerItem) async throws -> URL {
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

    private func reprocess() {
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

    private func printSettings(_ snap: VHSFilterSettings.Snapshot) {
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

    private func exportVideo() {
        guard let originalImage, !isExporting else {
            debugPrint("[ContentView] exportVideo guard failed: originalImage=\(originalImage != nil), isExporting=\(isExporting)")
            return
        }
        isExporting = true
        exportProgress = 0
        let snap = settings.snapshot()
        let videoURL = sourceVideoURL

        debugPrint("[ContentView] exportVideo started, hasVideoURL=\(videoURL != nil)")

        // Pause video preview during export
        videoPreviewEngine?.pause()

        Task.detached {
            do {
                let url: URL
                if let videoURL {
                    debugPrint("[ContentView] Calling exportFromVideo with URL: \(videoURL.lastPathComponent)")
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
                    debugPrint("[ContentView] Calling export (image mode)")
                    url = try await VideoExporter.export(
                        image: originalImage,
                        settings: snap
                    ) { value in
                        Task { @MainActor in
                            exportProgress = value
                        }
                    }
                }

                debugPrint("[ContentView] Export returned URL: \(url.lastPathComponent), saving to photo library...")
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }
                debugPrint("[ContentView] Saved to photo library successfully")

                try? FileManager.default.removeItem(at: url)

                await MainActor.run {
                    isExporting = false
                    videoPreviewEngine?.play()
                    showDoneIndicator()
                    debugPrint("[ContentView] Export flow complete, UI reset")
                }
            } catch {
                debugPrint("[ContentView] Export error: \(error)")
                await MainActor.run {
                    isExporting = false
                    videoPreviewEngine?.play()
                    saveErrorMessage = error.localizedDescription
                    showingSaveError = true
                }
            }
        }
    }

    private func savePhoto() {
        guard let imageToSave = processedImage ?? videoPreviewEngine?.currentFrame else { return }
        let saver = ImageSaver {
            showDoneIndicator()
        } onError: { error in
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
        saver.save(image: imageToSave)
    }

    private func showDoneIndicator() {
        showingDone = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            showingDone = false
        }
    }
}
