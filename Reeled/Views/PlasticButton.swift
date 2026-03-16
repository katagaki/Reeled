import SwiftUI

struct PlasticButton: View {
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
                .foregroundStyle(Color(red: 0.60, green: 0.60, blue: 0.65))
        }
        .frame(width: 64, height: 52)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: isPressed ? [
                                Color(red: 0.12, green: 0.12, blue: 0.14),
                                Color(red: 0.15, green: 0.15, blue: 0.17),
                                Color(red: 0.18, green: 0.18, blue: 0.20)
                            ] : [
                                Color(red: 0.26, green: 0.26, blue: 0.30),
                                Color(red: 0.18, green: 0.18, blue: 0.21),
                                Color(red: 0.14, green: 0.14, blue: 0.16)
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
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.03),
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
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.2),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.10)
                        ] : [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.06),
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(
            color: isPressed ? .clear : .black.opacity(0.4),
            radius: isPressed ? 0 : 2,
            y: isPressed ? 0 : 2
        )
        .shadow(
            color: isPressed ? .clear : .white.opacity(0.05),
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
