import SwiftUI
import UIKit

struct ProcessedImageView: View {
    let image: UIImage

    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.03)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.04),
                    Color.clear,
                    Color.clear,
                    Color.white.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .allowsHitTesting(false)
        }
    }
}
