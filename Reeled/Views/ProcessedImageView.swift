import SwiftUI
import UIKit

struct ProcessedImageView: View {
    @Environment(\.theme) private var theme

    let image: UIImage

    var body: some View {
        ZStack {
            theme.processedImageBackground

            Image(uiImage: image)
                .resizable()
                .scaledToFit()

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
    }
}
