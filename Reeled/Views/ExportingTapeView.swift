import SwiftUI

struct ExportingTapeView: View {
    @Environment(\.theme) private var theme

    let progress: Double
    let filename: String?

    @State private var reelRotation: Double = 0

    private var exportDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }

    /// Left reel starts full, right reel starts empty.
    private var leftFill: CGFloat {
        CGFloat(0.85 - 0.55 * progress)
    }
    private var rightFill: CGFloat {
        CGFloat(0.3 + 0.55 * progress)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.tapeShellTop,
                            theme.tapeShellMid,
                            theme.tapeShellBottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 280, height: 175)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.tapeShellHighlightTop,
                                    theme.tapeShellHighlightMid,
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    theme.tapeShellBorderTop,
                                    theme.tapeShellBorderMid,
                                    theme.tapeShellBorderBottom1,
                                    theme.tapeShellBorderBottom2
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: theme.tapeShellShadow, radius: 8, y: 4)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("Insert this side into recorder")
                        .font(.system(size: 6.5, weight: .medium))
                        .foregroundStyle(theme.tapeSmallText)
                    Spacer()
                    Text("▲")
                        .font(.system(size: 5))
                        .foregroundStyle(theme.tapeSmallText)
                    Spacer()
                    Text("Do not touch the tape inside")
                        .font(.system(size: 6.5, weight: .medium))
                        .foregroundStyle(theme.tapeSmallText)
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 5)

                VStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(theme.tapeGrooveLine)
                            .frame(width: 200, height: 1.5)
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(theme.tapeGrooveHighlight)
                                    .frame(height: 0.5)
                            }
                    }
                }
                .padding(.bottom, 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.tapeLabelTop,
                                theme.tapeLabelBottom
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 245, height: 48)
                    .overlay {
                        VStack(spacing: 3) {
                            HStack {
                                Text("VHS")
                                    .font(.system(size: 8, weight: .heavy))
                                    .foregroundStyle(theme.tapeLabelTitle)
                                Spacer()
                                Text(exportDateString)
                                    .font(.custom("Bradley Hand", size: 12))
                                    .bold()
                                    .foregroundStyle(theme.tapeLabelSubtitle)
                                    .zIndex(1)
                            }
                            .padding(.horizontal, 8)
                            Rectangle()
                                .fill(theme.tapeLabelLine)
                                .frame(height: 0.5)
                                .padding(.horizontal, 6)
                            HStack {
                                Rectangle()
                                    .fill(theme.tapeLabelLine.opacity(0.5))
                                    .frame(height: 0.5)
                                Rectangle()
                                    .fill(theme.tapeLabelLine.opacity(0.5))
                                    .frame(height: 0.5)
                            }
                            .padding(.horizontal, 6)
                            HStack {
                                Rectangle()
                                    .fill(theme.tapeLabelLine.opacity(0.5))
                                    .frame(height: 0.5)
                                Rectangle()
                                    .fill(theme.tapeLabelLine.opacity(0.5))
                                    .frame(height: 0.5)
                            }
                            .padding(.horizontal, 6)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(theme.tapeLabelBorder, lineWidth: 0.5)
                    }

                Spacer(minLength: 5)

                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.tapeWindowBackground)
                        .frame(width: 245, height: 50)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            theme.tapeWindowBorderTop,
                                            theme.tapeWindowBorderBottom
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }

                    HStack(spacing: 0) {
                        SpinningReelView(fillAmount: leftFill, rotation: reelRotation)
                            .frame(width: 44, height: 44)

                        Spacer()

                        Circle()
                            .fill(theme.tapePinFill)
                            .frame(width: 6, height: 6)
                            .overlay {
                                Circle()
                                    .strokeBorder(theme.tapePinBorder, lineWidth: 0.5)
                            }

                        Spacer()

                        SpinningReelView(fillAmount: rightFill, rotation: reelRotation)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 30)
                }

                Spacer(minLength: 6)
            }
            .frame(width: 280, height: 175)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                reelRotation = 360
            }
        }
    }
}

struct RecIndicatorView: View {
    @State private var isGlowing = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 12, height: 12)
                .shadow(color: .red.opacity(isGlowing ? 0.9 : 0.2), radius: isGlowing ? 10 : 2)
                .shadow(color: .red.opacity(isGlowing ? 0.5 : 0.0), radius: isGlowing ? 18 : 0)
                .opacity(isGlowing ? 1.0 : 0.3)
            Text("REC")
                .font(.custom("VCR-JP", size: 22))
                .foregroundStyle(.red)
                .shadow(color: .red.opacity(isGlowing ? 0.6 : 0.1), radius: isGlowing ? 8 : 1)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

private struct SpinningReelView: View {
    @Environment(\.theme) private var theme

    let fillAmount: CGFloat
    let rotation: Double

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
            // Hub with notches
            Circle()
                .fill(theme.reelHubFill)
                .frame(width: 14, height: 14)
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(theme.reelHubBorder.opacity(0.5))
                    .frame(width: 1.5, height: 5)
                    .offset(y: 3.5)
                    .rotationEffect(.degrees(Double(i) * 120))
            }
            Circle()
                .strokeBorder(theme.reelHubBorder, lineWidth: 1)
                .frame(width: 14, height: 14)
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(theme.reelSpoke)
                    .frame(width: 2, height: 6)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .rotationEffect(.degrees(rotation))
    }
}
