import CoreImage
import UIKit

extension VHSFilter {

    /// The year VHS was introduced by JVC.
    nonisolated static let vhsYear = 1976

    nonisolated static func generateDateStamp(size: CGSize, settings: VHSFilterSettings.Snapshot) -> CIImage? {
        guard settings.showDate || settings.showTime else { return nil }

        let components = Calendar.current.dateComponents([.month, .day, .hour, .minute], from: Date())
        var parts: [String] = []
        if settings.showDate {
            parts.append(String(format: "%d.%02d.%02d", vhsYear, components.month ?? 1, components.day ?? 1))
        }
        if settings.showTime {
            parts.append(String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0))
        }
        let dateString = parts.joined(separator: "  ")

        let renderer = pixelRenderer(size: size)
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
        }
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }
}
