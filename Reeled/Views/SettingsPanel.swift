import SwiftUI
import UIKit

struct VintageToggle: View {
    @Environment(\.theme) private var theme

    let label: String
    @Binding var isOn: Bool

    private let trackSize = CGSize(width: 48, height: 20)
    private let knobSize = CGSize(width: 24, height: 26)

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.custom("VCR-JP", size: 11))
                .foregroundStyle(theme.sliderLabel)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(theme.sliderTrack)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
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
                    .frame(width: trackSize.width, height: trackSize.height)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.65, blue: 0.2),
                                Color(red: 0.65, green: 0.32, blue: 0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 4
                        )
                    )
                    .frame(width: 7, height: 7)
                    .shadow(color: Color(red: 1.0, green: 0.6, blue: 0.2).opacity(0.6), radius: 2)
                    .opacity(isOn ? 1 : 0)
                    .padding(.leading, 8)

                knob
                    .offset(x: isOn ? trackSize.width - knobSize.width : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                    isOn.toggle()
                }
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        }
    }

    private var knob: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(white: 0.9), location: 0),
                            .init(color: Color(white: 0.68), location: 0.3),
                            .init(color: Color(white: 0.55), location: 0.5),
                            .init(color: Color(white: 0.72), location: 0.72),
                            .init(color: Color(white: 0.42), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Brushed-metal striations
            Canvas { context, canvasSize in
                var posY: CGFloat = 1
                var bright = true
                while posY < canvasSize.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 1, y: posY))
                    path.addLine(to: CGPoint(x: canvasSize.width - 1, y: posY))
                    context.stroke(
                        path,
                        with: .color(bright ? .white.opacity(0.09) : .black.opacity(0.07)),
                        lineWidth: 0.5
                    )
                    posY += 1.5
                    bright.toggle()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Grip ridges
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.35))
                        .frame(width: 1, height: 13)
                        .overlay(alignment: .trailing) {
                            Rectangle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: 0.5)
                                .offset(x: 0.75)
                        }
                }
            }
        }
        .frame(width: knobSize.width, height: knobSize.height)
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(white: 0.95),
                            Color(white: 0.4),
                            Color(white: 0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
        }
        .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1)
    }
}

struct VintageSlider: View {
    @Environment(\.theme) private var theme

    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var format: String = "%.2f"
    var onDragChanged: ((Bool) -> Void)?

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
                            DragGesture(minimumDistance: 0.5, coordinateSpace: .named("slider"))
                                .onChanged { gesture in
                                    if dragAxis == .undecided {
                                        let dx = abs(gesture.translation.width)
                                        let dy = abs(gesture.translation.height)
                                        dragAxis = dx > dy ? .horizontal : .vertical
                                    }

                                    guard dragAxis == .horizontal else { return }

                                    if !isDragging {
                                        isDragging = true
                                        onDragChanged?(true)
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                    let posX = gesture.location.x - thumbSize / 2
                                    let newFraction = max(0, min(1, posX / (width - thumbSize)))
                                    // swiftlint:disable:next line_length
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
                                        onDragChanged?(false)
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
