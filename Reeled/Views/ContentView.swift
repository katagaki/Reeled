import Photos
import PhotosUI
import SwiftUI
import UIKit

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

                    if processedImage == nil && !isProcessing && !isExporting {
                        EmptyStateView()
                    } else {
                        VStack(spacing: 0) {
                            Group {
                                if let processedImage {
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
                                    if processedImage != nil || isProcessing {
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
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                reprocess()
            }
        }
        .alert(String(localized: "Alert.Error.Title"), isPresented: $showingSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var inlineSettingsPanel: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 0)

            settingsGroup("COLOR") {
                VintageSlider(label: "SATURATION", value: $settings.saturation, range: 0...1.5)
                VintageSlider(label: "BRIGHTNESS", value: $settings.brightness, range: -0.2...0.2)
                VintageSlider(label: "CONTRAST", value: $settings.contrast, range: 0.5...1.5)
                VintageSlider(label: "WARMTH", value: $settings.warmth, range: 4000...7000)
            }

            settingsGroup("TEXTURE") {
                VintageSlider(label: "SOFTNESS", value: $settings.softness, range: 0...2)
                VintageSlider(label: "SHARPNESS", value: $settings.sharpness, range: 0...2)
                VintageSlider(label: "SCANLINES", value: $settings.scanlineOpacity, range: 0...0.2)
                VintageSlider(label: "NOISE LINES", value: $settings.noiseLines, range: 0...10)
                VintageSlider(label: "DISPLACEMENT", value: $settings.displacement, range: 0...8)
                VintageSlider(label: "GRAIN", value: $settings.grain, range: 0...0.5)
                VintageSlider(label: "MICRO DISTORTION", value: $settings.microDistortion, range: 0...1.0)
            }

            settingsGroup("ATMOSPHERE") {
                VintageSlider(label: "VIGNETTE", value: $settings.vignette, range: 0...1.0)
                VintageSlider(label: "BLOOM", value: $settings.bloom, range: 0...0.3)
                VintageSlider(label: "CHROMATIC ABERRATION", value: $settings.chromaticAberration, range: 0...4)
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
            return "INSERT PHOTO TO BEGIN"
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
                PhotosPicker(selection: $selectedItem, matching: .images) {
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
                    reprocess()
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
                .disabled(processedImage == nil || isProcessing || isExporting)
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
        let snap = settings.snapshot()
        printSettings(snap)

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
        guard let originalImage, !isExporting else { return }
        isExporting = true
        exportProgress = 0
        let snap = settings.snapshot()

        Task.detached {
            do {
                let url = try await VideoExporter.export(
                    image: originalImage,
                    settings: snap
                ) { value in
                    Task { @MainActor in
                        exportProgress = value
                    }
                }

                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }

                try? FileManager.default.removeItem(at: url)

                await MainActor.run {
                    isExporting = false
                    showDoneIndicator()
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    saveErrorMessage = error.localizedDescription
                    showingSaveError = true
                }
            }
        }
    }

    private func savePhoto() {
        guard let processedImage else { return }
        let saver = ImageSaver {
            showDoneIndicator()
        } onError: { error in
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
        saver.save(image: processedImage)
    }

    private func showDoneIndicator() {
        showingDone = true
        Task {
            try? await Task.sleep(for: .seconds(1))
            showingDone = false
        }
    }
}
