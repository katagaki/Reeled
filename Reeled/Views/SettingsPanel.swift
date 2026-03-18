import SwiftUI
import UIKit

struct VintageSlider: View {
    @Environment(\.theme) private var theme

    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.2f"

    @State private var isDragging = false
    @State private var isAtMin = false
    @State private var isAtMax = false
    @State private var dragAxis: DragAxis = .undecided

    private enum DragAxis {
        case undecided, horizontal, vertical
    }

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 22

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.custom("VCR-JP", size: 11))
                .foregroundStyle(theme.sliderLabel)
                .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { geo in
                let width = geo.size.width
                let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                let thumbX = fraction * (width - thumbSize)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(theme.sliderTrack)
                        .frame(height: trackHeight)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            theme.sliderTrackBorderTop,
                                            theme.sliderTrackBorderBottom
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
                                    theme.sliderAccent.opacity(0.7),
                                    theme.sliderAccent.opacity(0.4)
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
                                    theme.sliderThumbPressedTop,
                                    theme.sliderThumbPressedMid,
                                    theme.sliderThumbPressedBottom
                                ] : [
                                    theme.sliderThumbTop,
                                    theme.sliderThumbMid,
                                    theme.sliderThumbBottom
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
                                            theme.sliderThumbBorderTopPressed,
                                            theme.sliderThumbBorderMidPressed,
                                            theme.sliderThumbBorderBottom1Pressed,
                                            theme.sliderThumbBorderBottom2Pressed
                                        ] : [
                                            theme.sliderThumbBorderTopNormal,
                                            theme.sliderThumbBorderMidNormal,
                                            theme.sliderThumbBorderBottom1Normal,
                                            theme.sliderThumbBorderBottom2Normal
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .overlay {
                            Circle()
                                .fill(theme.sliderThumbDot.opacity(isDragging ? 0.3 : 0.2))
                                .frame(width: 6, height: 6)
                        }
                        .shadow(
                            color: isDragging ? .clear : theme.sliderThumbShadow,
                            radius: isDragging ? 0 : 2,
                            y: isDragging ? 0 : 1
                        )
                        .contentShape(Circle())
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 1, coordinateSpace: .named("slider"))
                                .onChanged { gesture in
                                    if dragAxis == .undecided {
                                        let dx = abs(gesture.translation.width)
                                        let dy = abs(gesture.translation.height)
                                        dragAxis = dx > dy ? .horizontal : .vertical
                                    }

                                    guard dragAxis == .horizontal else { return }

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
                                    let wasDragging = isDragging
                                    isDragging = false
                                    isAtMin = false
                                    isAtMax = false
                                    dragAxis = .undecided
                                    if wasDragging {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                        )
                        .offset(x: thumbX, y: isDragging ? 1 : 0)
                        .animation(.easeInOut(duration: 0.08), value: isDragging)
                }
                .coordinateSpace(name: "slider")
                .frame(height: thumbSize)
            }
            .frame(height: thumbSize)
        }
    }
}
