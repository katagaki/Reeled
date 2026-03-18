import Combine
import SwiftUI

struct LCDPanelView: View {
    let text: String
    let columns: Int
    let scrolling: Bool

    @State private var offset: Int = 0

    private let lcdGreen = Color(red: 0.7, green: 0.85, blue: 0.2)
    private let lcdDim = Color(red: 0.18, green: 0.22, blue: 0.08)
    private let lcdBackground = Color(red: 0.08, green: 0.10, blue: 0.04)

    init(text: String, columns: Int = 16, scrolling: Bool = true) {
        self.text = text
        self.columns = columns
        self.scrolling = scrolling
    }

    private var scrollBuffer: [Character] {
        let padding = Array(repeating: Character(" "), count: columns)
        return padding + Array(text) + padding
    }

    private var totalSteps: Int {
        scrollBuffer.count - columns + 1
    }

    private var visibleCharacters: [Character] {
        if scrolling {
            let buf = scrollBuffer
            var result: [Character] = []
            for col in 0..<columns {
                let idx = offset + col
                if idx < buf.count {
                    result.append(buf[idx])
                } else {
                    result.append(" ")
                }
            }
            return result
        } else {
            // Static: pad or truncate to fit columns
            let chars = Array(text)
            var result: [Character] = []
            for col in 0..<columns {
                if col < chars.count {
                    result.append(chars[col])
                } else {
                    result.append(" ")
                }
            }
            return result
        }
    }

    var body: some View {
        GeometryReader { geo in
            let totalSpacing = CGFloat(columns - 1) * 2
            let horizontalPad: CGFloat = 20
            let cellWidth = (geo.size.width - totalSpacing - horizontalPad) / CGFloat(columns)
            let fontSize = min(20, cellWidth * 1.2)
            HStack(spacing: 2) {
                ForEach(0..<columns, id: \.self) { col in
                    LCDCharacterCell(
                        character: visibleCharacters[col],
                        activeColor: lcdGreen,
                        dimColor: lcdDim,
                        fontSize: fontSize
                    )
                    .frame(width: cellWidth)
                }
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 28)
        .padding(.vertical, 4)
        .padding(.top, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(lcdBackground)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            lcdDim.opacity(0.6),
                            lcdDim.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
        .onReceive(
            Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()
        ) { _ in
            guard scrolling else { return }
            offset += 1
            if offset >= totalSteps {
                offset = 0
            }
        }
        .onChange(of: text) { _, _ in
            offset = 0
        }
    }
}

private struct LCDCharacterCell: View {
    let character: Character
    let activeColor: Color
    let dimColor: Color
    var fontSize: CGFloat = 20

    var body: some View {
        Text(String(character))
            .font(.custom("VCR-JP", size: fontSize))
            .foregroundStyle(character == " " ? .clear : activeColor)
            .shadow(color: activeColor.opacity(character == " " ? 0 : 0.5), radius: 2)
            .shadow(color: activeColor.opacity(character == " " ? 0 : 0.2), radius: 6)
    }
}
