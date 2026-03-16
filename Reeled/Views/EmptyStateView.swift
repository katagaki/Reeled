import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.20, green: 0.20, blue: 0.22),
                                Color(red: 0.14, green: 0.14, blue: 0.16),
                                Color(red: 0.11, green: 0.11, blue: 0.13)
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
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.01),
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
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.04),
                                        Color.black.opacity(0.2),
                                        Color.black.opacity(0.3)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: .black.opacity(0.5), radius: 8, y: 4)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Insert this side into recorder")
                            .font(.system(size: 6.5, weight: .medium))
                            .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.35))
                        Spacer()
                        Text("▲")
                            .font(.system(size: 5))
                            .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.35))
                        Spacer()
                        Text("Do not touch the tape inside")
                            .font(.system(size: 6.5, weight: .medium))
                            .foregroundStyle(Color(red: 0.32, green: 0.32, blue: 0.35))
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 5)

                    VStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(Color.black.opacity(0.35))
                                .frame(width: 200, height: 1.5)
                                .overlay(alignment: .top) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.04))
                                        .frame(height: 0.5)
                                }
                        }
                    }
                    .padding(.bottom, 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.94, green: 0.90, blue: 0.80),
                                    Color(red: 0.88, green: 0.84, blue: 0.74)
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
                                        .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.25))
                                    Spacer()
                                    Text("R-33L-D  Hi-Fi STEREO")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color(red: 0.45, green: 0.43, blue: 0.40))
                                }
                                .padding(.horizontal, 8)
                                Rectangle()
                                    .fill(Color(red: 0.75, green: 0.72, blue: 0.65))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 6)
                                HStack {
                                    Rectangle()
                                        .fill(Color(red: 0.75, green: 0.72, blue: 0.65).opacity(0.5))
                                        .frame(height: 0.5)
                                    Rectangle()
                                        .fill(Color(red: 0.75, green: 0.72, blue: 0.65).opacity(0.5))
                                        .frame(height: 0.5)
                                }
                                .padding(.horizontal, 6)
                                HStack {
                                    Rectangle()
                                        .fill(Color(red: 0.75, green: 0.72, blue: 0.65).opacity(0.5))
                                        .frame(height: 0.5)
                                    Rectangle()
                                        .fill(Color(red: 0.75, green: 0.72, blue: 0.65).opacity(0.5))
                                        .frame(height: 0.5)
                                }
                                .padding(.horizontal, 6)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(Color(red: 0.7, green: 0.67, blue: 0.60), lineWidth: 0.5)
                        }

                    Spacer(minLength: 5)

                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(red: 0.05, green: 0.05, blue: 0.06))
                            .frame(width: 245, height: 50)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.5),
                                                Color.white.opacity(0.05)
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
                                .fill(Color(red: 0.08, green: 0.08, blue: 0.09))
                                .frame(width: 6, height: 6)
                                .overlay {
                                    Circle()
                                        .strokeBorder(Color(red: 0.18, green: 0.18, blue: 0.20), lineWidth: 0.5)
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
                .foregroundStyle(Color(red: 0.50, green: 0.50, blue: 0.55))

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}
