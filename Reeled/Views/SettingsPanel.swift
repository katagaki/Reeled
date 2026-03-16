import SwiftUI
import UIKit

struct VintageSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.2f"

    @State private var isDragging = false
    @State private var isAtMin = false
    @State private var isAtMax = false

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 22
    private let accentBeige = Color(red: 0.88, green: 0.84, blue: 0.74)

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(red: 0.70, green: 0.68, blue: 0.62))
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geo in
                let width = geo.size.width
                let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                let thumbX = fraction * (width - thumbSize)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.07))
                        .frame(height: trackHeight)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.5),
                                            Color.white.opacity(0.04)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                        .padding(.horizontal, thumbSize / 2)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentBeige.opacity(0.7),
                                    accentBeige.opacity(0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(0, thumbX + thumbSize / 2), height: trackHeight)
                        .padding(.leading, thumbSize / 2)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isDragging ? [
                                    Color(red: 0.22, green: 0.22, blue: 0.26),
                                    Color(red: 0.16, green: 0.16, blue: 0.19),
                                    Color(red: 0.12, green: 0.12, blue: 0.14)
                                ] : [
                                    Color(red: 0.32, green: 0.32, blue: 0.36),
                                    Color(red: 0.20, green: 0.20, blue: 0.23),
                                    Color(red: 0.15, green: 0.15, blue: 0.17)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: isDragging ? [
                                            Color.black.opacity(0.25),
                                            Color.black.opacity(0.15),
                                            Color.white.opacity(0.04),
                                            Color.white.opacity(0.08)
                                        ] : [
                                            Color.white.opacity(0.20),
                                            Color.white.opacity(0.05),
                                            Color.black.opacity(0.15),
                                            Color.black.opacity(0.25)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .overlay {
                            Circle()
                                .fill(Color.black.opacity(isDragging ? 0.3 : 0.2))
                                .frame(width: 6, height: 6)
                        }
                        .shadow(
                            color: isDragging ? .clear : .black.opacity(0.4),
                            radius: isDragging ? 0 : 2,
                            y: isDragging ? 0 : 1
                        )
                        .offset(x: thumbX, y: isDragging ? 1 : 0)
                        .animation(.easeInOut(duration: 0.08), value: isDragging)
                }
                .frame(height: thumbSize)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                isDragging = true
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                            let x = gesture.location.x - thumbSize / 2
                            let newFraction = max(0, min(1, x / (width - thumbSize)))
                            let newValue = range.lowerBound + newFraction * (range.upperBound - range.lowerBound)
                            value = newValue

                            let nowAtMin = newFraction <= 0
                            let nowAtMax = newFraction >= 1
                            if nowAtMin && !isAtMin {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }
                            if nowAtMax && !isAtMax {
                                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            }
                            isAtMin = nowAtMin
                            isAtMax = nowAtMax
                        }
                        .onEnded { _ in
                            isDragging = false
                            isAtMin = false
                            isAtMax = false
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                )
            }
            .frame(height: thumbSize)
        }
    }
}
