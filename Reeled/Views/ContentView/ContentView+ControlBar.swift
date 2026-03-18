import PhotosUI
import SwiftUI

extension ContentView {

    var lcdText: String {
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

    var lcdScrolling: Bool {
        if showingDone || isExporting || isProcessing {
            return false
        }
        return originalImage == nil
    }

    var controlBar: some View {
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
                .buttonStyle(
                    PlasticButtonStyle(
                        label: String(localized: "Button.Insert"),
                        systemImage: "eject.fill",
                        tint: .blue
                    )
                )
                .disabled(isExporting)

                Button {
                    settings.resetToDefaults()
                } label: {
                    Text("")
                }
                .buttonStyle(
                    PlasticButtonStyle(
                        label: String(localized: "Button.Reset"),
                        systemImage: "arrow.uturn.backward",
                        tint: .red
                    )
                )
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
                .buttonStyle(
                    PlasticButtonStyle(
                        label: String(localized: "Button.Rewind"),
                        systemImage: "backward.end.fill",
                        tint: .gray
                    )
                )
                .disabled(originalImage == nil || isProcessing || isExporting)

                Button {
                    exportVideo()
                } label: {
                    Text("")
                }
                .buttonStyle(
                    PlasticButtonStyle(
                        label: String(localized: "Button.Video"),
                        systemImage: "film.stack",
                        tint: .orange
                    )
                )
                .disabled(originalImage == nil || isProcessing || isExporting)

                Button {
                    savePhoto()
                } label: {
                    Text("")
                }
                .buttonStyle(
                    PlasticButtonStyle(
                        label: String(localized: "Button.Image"),
                        systemImage: "photo",
                        tint: .orange
                    )
                )
                .disabled((processedImage == nil && videoPreviewEngine == nil) || sourceVideoAsset != nil || isProcessing || isExporting)
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
}
