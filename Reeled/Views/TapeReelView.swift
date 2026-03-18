import SwiftUI

struct TapeReelView: View {
    @Environment(\.theme) private var theme

    let fillAmount: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            theme.reelTape1,
                            theme.reelTape2,
                            theme.reelTape3
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 22 * fillAmount
                    )
                )
                .frame(width: 44 * fillAmount, height: 44 * fillAmount)
            Circle()
                .strokeBorder(theme.reelTapeBorder, lineWidth: 1)
                .frame(width: 44 * fillAmount, height: 44 * fillAmount)
            Circle()
                .fill(theme.reelHubFill)
                .frame(width: 14, height: 14)
            ForEach(0..<3, id: \.self) { idx in
                Capsule()
                    .fill(theme.reelHubBorder.opacity(0.5))
                    .frame(width: 1.5, height: 5)
                    .offset(y: 3.5)
                    .rotationEffect(.degrees(Double(idx) * 120))
            }
            Circle()
                .strokeBorder(theme.reelHubBorder, lineWidth: 1)
                .frame(width: 14, height: 14)
            ForEach(0..<6, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(theme.reelSpoke)
                    .frame(width: 2, height: 6)
                    .rotationEffect(.degrees(Double(idx) * 60))
            }
        }
    }
}
