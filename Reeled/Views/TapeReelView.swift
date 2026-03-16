import SwiftUI

struct TapeReelView: View {
    let fillAmount: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.08, green: 0.06, blue: 0.04),
                            Color(red: 0.12, green: 0.10, blue: 0.08),
                            Color(red: 0.06, green: 0.05, blue: 0.04)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 22 * fillAmount
                    )
                )
                .frame(width: 44 * fillAmount, height: 44 * fillAmount)
            Circle()
                .strokeBorder(Color(red: 0.15, green: 0.13, blue: 0.10), lineWidth: 1)
                .frame(width: 44 * fillAmount, height: 44 * fillAmount)
            Circle()
                .fill(Color(red: 0.20, green: 0.20, blue: 0.22))
                .frame(width: 14, height: 14)
            Circle()
                .strokeBorder(Color(red: 0.28, green: 0.28, blue: 0.30), lineWidth: 1)
                .frame(width: 14, height: 14)
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color(red: 0.30, green: 0.30, blue: 0.32))
                    .frame(width: 2, height: 6)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
    }
}
