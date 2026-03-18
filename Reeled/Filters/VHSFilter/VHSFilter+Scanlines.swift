import CoreImage
import UIKit

extension VHSFilter {

    nonisolated static func generateScanlines(size: CGSize, scale: CGFloat, seed: UInt64, opacity: Double) -> CIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let lineSpacing = max(4.0, 2.0 * scale)
        let gapHeight = max(1.0, lineSpacing * 0.35)
        var rng = SeededRNG(seed: seed &+ 99999)

        let image = renderer.image { ctx in
            let gc = ctx.cgContext

            UIColor.white.setFill()
            gc.fill(CGRect(origin: .zero, size: size))

            var posY: CGFloat = 0
            while posY < size.height {
                let gapAlpha = CGFloat(opacity) * CGFloat.random(in: 0.7...1.0, using: &rng)
                gc.setFillColor(UIColor.black.withAlphaComponent(gapAlpha).cgColor)
                gc.fill(CGRect(x: 0, y: posY, width: size.width, height: gapHeight))

                let phosphorAlpha = CGFloat(opacity) * 0.3
                let tintChoice = Int.random(in: 0...2, using: &rng)
                let tintColor: UIColor
                switch tintChoice {
                case 0: tintColor = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: phosphorAlpha)
                case 1: tintColor = UIColor(red: 0.9, green: 1.0, blue: 0.95, alpha: phosphorAlpha)
                default: tintColor = UIColor(red: 0.92, green: 0.92, blue: 1.0, alpha: phosphorAlpha)
                }
                gc.setFillColor(tintColor.cgColor)
                let litRowHeight = lineSpacing - gapHeight
                gc.fill(CGRect(x: 0, y: posY + gapHeight, width: size.width, height: litRowHeight))

                if Bool.random(using: &rng) {
                    let wobbleAlpha = CGFloat(opacity) * CGFloat.random(in: 0.05...0.15, using: &rng)
                    gc.setFillColor(UIColor.white.withAlphaComponent(wobbleAlpha).cgColor)
                    gc.fill(CGRect(x: 0, y: posY + gapHeight, width: size.width, height: litRowHeight))
                }

                posY += lineSpacing
            }
        }
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }

    nonisolated static func generateNoiseLines(size: CGSize, scale: CGFloat, seed: UInt64, lineCount: Int) -> CIImage? {
        guard lineCount > 0 else { return nil }
        var rng = SeededRNG(seed: seed)
        let renderer = UIGraphicsImageRenderer(size: size)
        let scaledUnit = max(1.0, scale * 0.8)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let gc = ctx.cgContext

            for _ in 0..<lineCount {
                let lineY = CGFloat.random(in: 0...size.height, using: &rng)
                let baseHeight = CGFloat.random(in: 3...8, using: &rng) * scaledUnit
                let alpha = CGFloat.random(in: 0.05...0.14, using: &rng)

                let blobCount = Int.random(in: 2...5, using: &rng)
                for _ in 0..<blobCount {
                    let blobX = CGFloat.random(in: -size.width * 0.1...0, using: &rng)
                    let blobWidth = CGFloat.random(in: size.width * 0.5...size.width * 1.2, using: &rng)
                    let blobY = lineY + CGFloat.random(in: -baseHeight * 0.3...baseHeight * 0.3, using: &rng)
                    let blobH = baseHeight * CGFloat.random(in: 0.5...1.5, using: &rng)
                    let blobAlpha = alpha * CGFloat.random(in: 0.4...1.0, using: &rng)

                    let rect = CGRect(x: blobX, y: blobY, width: blobWidth, height: blobH)
                    let cornerRadius = min(blobH * 0.4, 6.0 * scaledUnit)

                    gc.setFillColor(UIColor.white.withAlphaComponent(blobAlpha).cgColor)
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
                    gc.addPath(path.cgPath)
                    gc.fillPath()
                }
            }

            let glitchCount = Int.random(in: 1...2, using: &rng)
            for _ in 0..<glitchCount {
                let glitchY = CGFloat.random(in: 0...size.height, using: &rng)
                let height = CGFloat.random(in: 8...18, using: &rng) * scaledUnit
                let alpha = CGFloat.random(in: 0.03...0.08, using: &rng)

                gc.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                let rect = CGRect(x: 0, y: glitchY, width: size.width, height: height)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: height * 0.3)
                gc.addPath(path.cgPath)
                gc.fillPath()
            }

            let bottomH = CGFloat.random(in: 6...14, using: &rng) * scaledUnit
            let bottomAlpha = CGFloat.random(in: 0.06...0.12, using: &rng)
            gc.setFillColor(UIColor.white.withAlphaComponent(bottomAlpha).cgColor)
            let bottomRect = CGRect(x: 0, y: size.height - bottomH, width: size.width, height: bottomH)
            gc.fill(bottomRect)
        }
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }
}
