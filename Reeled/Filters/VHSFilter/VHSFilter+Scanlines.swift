import CoreImage
import UIKit

extension VHSFilter {

    nonisolated static func generateScanlines(size: CGSize, scale: CGFloat, seed: UInt64, opacity: Double) -> CIImage? {
        let renderer = pixelRenderer(size: size)
        // ~240 visible CRT lines: 2px pitch at 480
        let pitch = max(2.0, (size.height / 240.0).rounded())
        let gapHeight = max(1.0, (pitch * 0.5).rounded())
        var rng = SeededRNG(seed: seed &+ 99999)

        let image = renderer.image { ctx in
            let cgc = ctx.cgContext

            UIColor.white.setFill()
            cgc.fill(CGRect(origin: .zero, size: size))

            var posY: CGFloat = 0
            while posY < size.height {
                let gapAlpha = CGFloat(opacity) * CGFloat.random(in: 0.9...1.0, using: &rng)
                cgc.setFillColor(UIColor.black.withAlphaComponent(gapAlpha).cgColor)
                cgc.fill(CGRect(x: 0, y: posY, width: size.width, height: gapHeight))
                posY += pitch
            }
        }
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }

    // swiftlint:disable:next function_body_length
    nonisolated static func generateNoiseLines(size: CGSize, scale: CGFloat, seed: UInt64, lineCount: Int) -> CIImage? {
        guard lineCount > 0 else { return nil }
        var rng = SeededRNG(seed: seed)
        let renderer = pixelRenderer(size: size)
        let scaledUnit = max(1.0, scale * 0.8)

        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let cgc = ctx.cgContext

            // Dropout streaks: hot head, then ragged segments that sputter out
            for _ in 0..<lineCount {
                let clusterY = CGFloat.random(in: 0...size.height, using: &rng)
                let streakCount = Int.random(in: 1...3, using: &rng)

                for _ in 0..<streakCount {
                    let streakY = clusterY + CGFloat.random(in: -14...14, using: &rng) * scaledUnit
                    let baseHeight = CGFloat.random(in: 1.0...2.2, using: &rng) * scaledUnit
                    let headX = CGFloat.random(in: 0...size.width * 0.85, using: &rng)
                    let length = CGFloat.random(in: size.width * 0.05...size.width * 0.5, using: &rng)
                    let baseAlpha = CGFloat.random(in: 0.35...0.8, using: &rng)

                    cgc.setFillColor(UIColor(white: 1.0, alpha: min(1.0, baseAlpha * 1.4)).cgColor)
                    let headWidth = CGFloat.random(in: 4...10, using: &rng) * scaledUnit
                    cgc.fill(CGRect(x: headX, y: streakY, width: headWidth, height: baseHeight))

                    var segX = headX + headWidth
                    while segX < headX + length {
                        let segWidth = CGFloat.random(in: 3...12, using: &rng) * scaledUnit
                        let progress = (segX - headX) / length
                        let gapChance = 0.08 + progress * 0.6

                        if CGFloat.random(in: 0...1, using: &rng) > gapChance {
                            let flicker = CGFloat.random(in: 0.45...1.3, using: &rng)
                            let segAlpha = min(1.0, baseAlpha * (1.0 - progress * 0.85) * flicker)
                            let segHeight = baseHeight * CGFloat.random(in: 0.6...1.2, using: &rng)
                            let segY = streakY + CGFloat.random(in: -0.8...0.8, using: &rng) * scaledUnit

                            cgc.setFillColor(UIColor(white: 1.0, alpha: segAlpha).cgColor)
                            cgc.fill(CGRect(x: segX, y: segY, width: segWidth, height: segHeight))
                        }
                        segX += segWidth
                    }
                }
            }

            // Tracking-noise bands as sparse dashed speckle
            let bandCount = Int.random(in: 0...2, using: &rng)
            for _ in 0..<bandCount {
                let bandY = CGFloat.random(in: 0...size.height, using: &rng)
                let bandHeight = CGFloat.random(in: 6...16, using: &rng) * scaledUnit
                let rowHeight = max(1.0, scaledUnit)

                var rowY = bandY
                while rowY < bandY + bandHeight {
                    var xPos = CGFloat.random(in: -30...0, using: &rng)
                    while xPos < size.width {
                        let dashWidth = CGFloat.random(in: 6...40, using: &rng) * scaledUnit
                        if Bool.random(using: &rng) {
                            let alpha = CGFloat.random(in: 0.03...0.1, using: &rng)
                            cgc.setFillColor(UIColor(white: 1.0, alpha: alpha).cgColor)
                            cgc.fill(CGRect(x: xPos, y: rowY, width: dashWidth, height: rowHeight))
                        }
                        xPos += dashWidth + CGFloat.random(in: 2...24, using: &rng) * scaledUnit
                    }
                    rowY += rowHeight * CGFloat.random(in: 1.0...2.0, using: &rng)
                }
            }
        }
        guard let cgImage = image.cgImage else { return nil }

        // Slight horizontal smear so no edge stays pixel-crisp
        return CIImage(cgImage: cgImage)
            .applyingFilter("CIMotionBlur", parameters: [
                kCIInputRadiusKey: max(1.0, 1.5 * scale),
                kCIInputAngleKey: 0.0
            ])
            .cropped(to: CGRect(origin: .zero, size: size))
    }
}
