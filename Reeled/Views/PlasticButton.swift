import SwiftUI

struct PlasticButton: View {
    @Environment(\.theme) private var theme

    let label: String
    let systemImage: String
    let tint: Color
    var isPressed: Bool = false

    private var accentColor: Color {
        switch tint {
        case .blue: Color(red: 0.35, green: 0.50, blue: 0.75)
        case .green: Color(red: 0.35, green: 0.65, blue: 0.40)
        case .orange: Color(red: 0.80, green: 0.55, blue: 0.20)
        case .red: Color(red: 0.75, green: 0.30, blue: 0.30)
        case .gray: Color(red: 0.55, green: 0.55, blue: 0.60)
        default: Color(red: 0.5, green: 0.5, blue: 0.5)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isPressed ? accentColor.opacity(0.6) : accentColor)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(theme.buttonLabelColor)
        }
        .frame(width: 64, height: 52)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: isPressed ? [
                                theme.buttonPressedTop,
                                theme.buttonPressedMid,
                                theme.buttonPressedBottom
                            ] : [
                                theme.buttonGradientTop,
                                theme.buttonGradientMid,
                                theme.buttonGradientBottom
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                if !isPressed {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.buttonHighlightTop,
                                    theme.buttonHighlightMid,
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            }
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    LinearGradient(
                        colors: isPressed ? [
                            theme.buttonBorderTopPressed,
                            theme.buttonBorderMidPressed,
                            theme.buttonBorderBottomPressed1,
                            theme.buttonBorderBottomPressed2
                        ] : [
                            theme.buttonBorderTopNormal,
                            theme.buttonBorderMidNormal,
                            theme.buttonBorderBottomNormal1,
                            theme.buttonBorderBottomNormal2
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(
            color: isPressed ? .clear : theme.buttonShadow,
            radius: isPressed ? 0 : 2,
            y: isPressed ? 0 : 2
        )
        .shadow(
            color: isPressed ? .clear : theme.buttonTopShadow,
            radius: 0,
            y: isPressed ? 0 : -0.5
        )
        .offset(y: isPressed ? 2 : 0)
        .animation(.easeInOut(duration: 0.08), value: isPressed)
    }
}

struct PlasticButtonStyle: ButtonStyle {
    let label: String
    let systemImage: String
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        PlasticButton(
            label: label,
            systemImage: systemImage,
            tint: tint,
            isPressed: configuration.isPressed
        )
        .onChange(of: configuration.isPressed) { _, isPressed in
            if isPressed {
                let press = UIImpactFeedbackGenerator(style: .medium)
                press.impactOccurred()
            } else {
                let release = UIImpactFeedbackGenerator(style: .light)
                release.impactOccurred()
            }
        }
    }
}
