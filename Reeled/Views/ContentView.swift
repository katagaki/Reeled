import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {

    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var settings = VHSFilterSettings()
    @State private var debounceTask: Task<Void, Never>?

    private let shellDark = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let shellMid = Color(red: 0.22, green: 0.22, blue: 0.25)
    private let shellLight = Color(red: 0.32, green: 0.32, blue: 0.36)
    private let shellHighlight = Color(red: 0.45, green: 0.45, blue: 0.50)
    private let plasticBlue = Color(red: 0.15, green: 0.20, blue: 0.35)
    private let labelCream = Color(red: 0.92, green: 0.88, blue: 0.78)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.16, blue: 0.18),
                    Color(red: 0.10, green: 0.10, blue: 0.12),
                    Color(red: 0.08, green: 0.08, blue: 0.10)
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
                                    Color(red: 0.24, green: 0.24, blue: 0.27),
                                    Color(red: 0.18, green: 0.18, blue: 0.21),
                                    Color(red: 0.14, green: 0.14, blue: 0.16)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.02),
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
                            .fill(Color.black.opacity(0.4))
                            .frame(height: 1)
                    }

                GeometryReader { geo in
                    let imageHeight = geo.size.height * 0.5
                    let slidersHeight = geo.size.height * 0.5

                    VStack(spacing: 0) {
                        Group {
                            if let processedImage {
                                ProcessedImageView(image: processedImage)
                            } else if isProcessing {
                                processingView
                            } else {
                                EmptyStateView()
                            }
                        }
                        .frame(height: imageHeight)
                        .clipped()

                        ScrollView {
                            if processedImage != nil || isProcessing {
                                inlineSettingsPanel
                            }
                        }
                        .frame(height: slidersHeight)
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
        .alert(String(localized: "Alert.SaveSuccess.Title"), isPresented: $showingSaveSuccess) {
            Button("OK") {}
        } message: {
            Text(String(localized: "Alert.SaveSuccess.Message"))
        }
        .alert(String(localized: "Alert.Error.Title"), isPresented: $showingSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage)
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(red: 0.4, green: 0.7, blue: 0.5))
            Text(String(localized: "Processing.Dubbing"))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 0.5))
            Spacer()
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
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.55, green: 0.55, blue: 0.60))
                .padding(.leading, 4)

            VStack(spacing: 14) {
                content()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.14, green: 0.14, blue: 0.16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.06),
                                        Color.black.opacity(0.2)
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

    private var controlBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Insert"), systemImage: "eject.fill", tint: .blue))

                Spacer()

                Button {
                    settings.resetToDefaults()
                } label: {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Reset"), systemImage: "arrow.uturn.backward", tint: .red))
                .disabled(originalImage == nil)
                .opacity(originalImage == nil ? 0.4 : 1.0)

                Spacer()

                Button {
                    reprocess()
                } label: {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Rewind"), systemImage: "backward.end.fill", tint: .green))
                .disabled(originalImage == nil || isProcessing)
                .opacity(originalImage == nil ? 0.4 : 1.0)

                Spacer()

                Button {
                    savePhoto()
                } label: {
                    Text("")
                }
                .buttonStyle(PlasticButtonStyle(label: String(localized: "Button.Save"), systemImage: "printer.filled.and.paper.inverse", tint: .orange))
                .disabled(processedImage == nil || isProcessing)
                .opacity(processedImage == nil ? 0.4 : 1.0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .background(
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.20, blue: 0.23),
                        Color(red: 0.14, green: 0.14, blue: 0.16),
                        Color(red: 0.10, green: 0.10, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
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

            await MainActor.run {
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
        [VHS Settings] chromatic=\(snap.chromaticAberration) sat=\(snap.saturation) \
        bright=\(snap.brightness) contrast=\(snap.contrast) warmth=\(snap.warmth) \
        soft=\(snap.softness) sharp=\(snap.sharpness) scanlines=\(snap.scanlineOpacity) \
        noise=\(snap.noiseLines) disp=\(snap.displacement) grain=\(snap.grain) \
        vignette=\(snap.vignette) bloom=\(snap.bloom)
        """)
        #endif
    }

    private func savePhoto() {
        guard let processedImage else { return }
        let saver = ImageSaver {
            showingSaveSuccess = true
        } onError: { error in
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
        saver.save(image: processedImage)
    }
}

#Preview {
    ContentView()
}
