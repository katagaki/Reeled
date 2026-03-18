import SwiftUI
import UIKit

struct FilteredVideoPreviewView: View {
    @Environment(\.theme) private var theme

    let engine: VideoPreviewEngine

    var body: some View {
        ZStack {
            theme.processedImageBackground

            if let frame = engine.currentFrame {
                Image(uiImage: frame)
                    .resizable()
                    .scaledToFit()
            }

            LinearGradient(
                colors: [
                    theme.processedImageOverlayTop,
                    Color.clear,
                    Color.clear,
                    theme.processedImageOverlayBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if engine.isPlaying {
                engine.pause()
            } else {
                engine.play()
            }
        }
    }
}
