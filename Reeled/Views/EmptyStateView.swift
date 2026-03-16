import SwiftUI

struct EmptyStateView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 32) {
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
                                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                        .foregroundStyle(theme.tapeLabelTitle)
                                    Spacer()
                                    Text("R-33L-D  Hi-Fi STEREO")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundStyle(theme.tapeLabelSubtitle)
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
                            TapeReelView(fillAmount: 0.85)
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

                            TapeReelView(fillAmount: 0.4)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 30)
                    }

                    Spacer(minLength: 6)
                }
                .frame(width: 280, height: 175)
            }

            Text(String(localized: "EmptyState.SelectPhoto"))
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.emptyStateText)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}
