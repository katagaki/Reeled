import AVFoundation
import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ContentView: View {

    @Environment(\.theme) var theme
    @State var selectedItem: PhotosPickerItem?
    @State var originalImage: UIImage?
    @State var processedImage: UIImage?
    @State var isProcessing = false
    @State var showingSaveError = false
    @State var saveErrorMessage = ""
    @State var settings = VHSFilterSettings()
    @State var debounceTask: Task<Void, Never>?
    @State var originalFilename: String?
    @State var isExporting = false
    @State var exportProgress: Double = 0
    @State var showingDone = false
    @State var sourceVideoAsset: AVAsset?
    @State var sourceVideoURL: URL?
    @State var videoPreviewEngine: VideoPreviewEngine?
    @State var activeDragCount: Int = 0

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
}
