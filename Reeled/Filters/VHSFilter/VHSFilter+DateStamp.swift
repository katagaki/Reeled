import CoreImage
import UIKit

extension VHSFilter {

    nonisolated static func generateDateStamp(size: CGSize, seed: UInt64) -> CIImage? {
        var rng = SeededRNG(seed: seed)

        let year = Int.random(in: 1...31, using: &rng)
        let month = Int.random(in: 1...12, using: &rng)
        let day = Int.random(in: 1...28, using: &rng)
        let hour = Int.random(in: 0...23, using: &rng)
        let minute = Int.random(in: 0...59, using: &rng)

        let formats = [
            String(format: "%d.%02d.%02d  %02d:%02d", 1988 + year, month, day, hour, minute),
            String(format: "H%d.%d.%d  %d:%02d", year, month, day, hour, minute),
            String(format: "%d/%02d/%02d  %02d:%02d", 1988 + year, month, day, hour, minute),
            String(format: "'%02d %02d.%02d  %02d:%02d", (1988 + year) % 100, month, day, hour, minute)
        ]
        let dateString = formats[Int.random(in: 0..<formats.count, using: &rng)]

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let fontSize: CGFloat = max(size.width * 0.035, 14)
            let font = UIFont(
                name: "VCR-JP",
                size: fontSize
            ) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 0.85),
                .paragraphStyle: paragraphStyle
            ]

            let textSize = dateString.size(withAttributes: attributes)
            let xPos = size.width - textSize.width - size.width * 0.05
            let yPos = size.height - textSize.height - size.height * 0.07

            let glowAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.2),
                .paragraphStyle: paragraphStyle
            ]
            dateString.draw(at: CGPoint(x: xPos - 1, y: yPos - 1), withAttributes: glowAttributes)
            dateString.draw(at: CGPoint(x: xPos + 1, y: yPos + 1), withAttributes: glowAttributes)

            dateString.draw(at: CGPoint(x: xPos, y: yPos), withAttributes: attributes)

            let playString = "PLAY  ▶"
            let playFont = UIFont(
                name: "VCR-JP",
                size: fontSize * 0.9
            ) ?? UIFont.monospacedSystemFont(ofSize: fontSize * 0.9, weight: .bold)
            let playAttributes: [NSAttributedString.Key: Any] = [
                .font: playFont,
                .foregroundColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85),
                .paragraphStyle: paragraphStyle
            ]
            let playGlowAttributes: [NSAttributedString.Key: Any] = [
                .font: playFont,
                .foregroundColor: UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2),
                .paragraphStyle: paragraphStyle
            ]
            let playX = size.width * 0.05
            let playY = size.height * 0.06
            playString.draw(at: CGPoint(x: playX - 1, y: playY - 1), withAttributes: playGlowAttributes)
            playString.draw(at: CGPoint(x: playX + 1, y: playY + 1), withAttributes: playGlowAttributes)
            playString.draw(at: CGPoint(x: playX, y: playY), withAttributes: playAttributes)
        }
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }
}
