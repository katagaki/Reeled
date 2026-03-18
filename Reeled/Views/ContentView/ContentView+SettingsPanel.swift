import SwiftUI

extension ContentView {

    var inlineSettingsPanel: some View {
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
                VintageSlider(
                    label: "SATURATION",
                    value: $settings.saturation,
                    range: 0...1.5,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "BRIGHTNESS",
                    value: $settings.brightness,
                    range: -0.2...0.2,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "CONTRAST",
                    value: $settings.contrast,
                    range: 0.5...1.5,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "WARMTH",
                    value: $settings.warmth,
                    range: 4000...7000,
                    onDragChanged: dragHandler
                )
            }

            settingsGroup("TEXTURE") {
                VintageSlider(
                    label: "SOFTNESS",
                    value: $settings.softness,
                    range: 0...2,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "SHARPNESS",
                    value: $settings.sharpness,
                    range: 0...2,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "SCANLINES",
                    value: $settings.scanlineOpacity,
                    range: 0...0.2,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "NOISE LINES",
                    value: $settings.noiseLines,
                    range: 0...10,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "DISPLACEMENT",
                    value: $settings.displacement,
                    range: 0...8,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "GRAIN",
                    value: $settings.grain,
                    range: 0...0.5,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "MICRO DISTORTION",
                    value: $settings.microDistortion,
                    range: 0...1.0,
                    onDragChanged: dragHandler
                )
            }

            settingsGroup("ATMOSPHERE") {
                VintageSlider(
                    label: "VIGNETTE",
                    value: $settings.vignette,
                    range: 0...1.0,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "BLOOM",
                    value: $settings.bloom,
                    range: 0...0.3,
                    onDragChanged: dragHandler
                )
                VintageSlider(
                    label: "CHROMATIC ABERRATION",
                    value: $settings.chromaticAberration,
                    range: 0...4,
                    onDragChanged: dragHandler
                )
            }

            Spacer().frame(height: 0)
        }
    }

    @ViewBuilder
    func settingsGroup(_ title: String, @ViewBuilder content: () -> some View) -> some View {
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
}
