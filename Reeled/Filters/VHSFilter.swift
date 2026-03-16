import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct VHSFilter: Sendable {

    nonisolated static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// VHS horizontal resolution was ~320 lines mapped to a 4:3 frame.
    /// We use 640x480 as a recognisable doubled-up VHS frame size.
    nonisolated private static let vhsLongEdge: CGFloat = 640
    nonisolated private static let vhsShortEdge: CGFloat = 480

    nonisolated static func apply(to image: UIImage, settings: VHSFilterSettings.Snapshot) -> UIImage? {
        guard let original = CIImage(image: image) else { return nil }

        // Center-crop to 4:3, then scale down to VHS resolution (640x480)
        let srcW = original.extent.width
        let srcH = original.extent.height
        let isLandscape = srcW >= srcH
        let targetW: CGFloat = isLandscape ? vhsLongEdge : vhsShortEdge
        let targetH: CGFloat = isLandscape ? vhsShortEdge : vhsLongEdge
        let targetAspect = targetW / targetH

        // Crop to target aspect ratio from center
        let srcAspect = srcW / srcH
        let cropRect: CGRect
        if srcAspect > targetAspect {
            // Source is wider — crop sides
            let cropW = srcH * targetAspect
            cropRect = CGRect(x: (srcW - cropW) / 2, y: 0, width: cropW, height: srcH)
        } else {
            // Source is taller — crop top/bottom
            let cropH = srcW / targetAspect
            cropRect = CGRect(x: 0, y: (srcH - cropH) / 2, width: srcW, height: cropH)
        }
        let cropped = original.cropped(to: cropRect)

        // Scale to VHS dimensions
        let scaleX = targetW / cropped.extent.width
        let scaleY = targetH / cropped.extent.height
        let scaled = cropped.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        // Reset origin to (0,0) after transforms
        let ciImage = scaled.transformed(by: CGAffineTransform(translationX: -scaled.extent.origin.x,
                                                                y: -scaled.extent.origin.y))

        let extent = ciImage.extent
        let seed = UInt64.random(in: 0...UInt64.max)
        let scale = extent.width / 1000.0

        var result = ciImage

        result = result.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: settings.saturation,
            kCIInputBrightnessKey: settings.brightness,
            kCIInputContrastKey: settings.contrast
        ])

        result = result.applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 5800, y: 0),
            "inputTargetNeutral": CIVector(x: settings.warmth, y: 25)
        ])

        let chromaBleedRadius = max(1.5, 3.0 * scale)
        let blurredForChroma = result.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: chromaBleedRadius,
            kCIInputAngleKey: 0.0
        ]).cropped(to: extent)
        result = result.applyingFilter("CIColorBlendMode", parameters: [
            kCIInputBackgroundImageKey: blurredForChroma
        ]).cropped(to: extent)

        if settings.softness > 0 {
            result = result.applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: min(2.0, settings.softness * scale)
            ]).cropped(to: extent)

            let hBlurRadius = min(1.5, settings.softness * scale * 0.4)
            if hBlurRadius > 0.3 {
                result = result.applyingFilter("CIMotionBlur", parameters: [
                    kCIInputRadiusKey: hBlurRadius,
                    kCIInputAngleKey: 0.0
                ]).cropped(to: extent)
            }
        }

        if settings.sharpness > 0 {
            result = result.applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: settings.sharpness
            ]).cropped(to: extent)
        }

        if settings.scanlineOpacity > 0 {
            if let scanlines = generateScanlines(size: extent.size, scale: scale, seed: seed, opacity: settings.scanlineOpacity) {
                result = scanlines
                    .applyingFilter("CIMultiplyCompositing", parameters: [
                        kCIInputBackgroundImageKey: result
                    ])
                    .cropped(to: extent)
            }
        }

        if settings.noiseLines > 0 {
            if let noise = generateNoiseLines(size: extent.size, scale: scale, seed: seed, lineCount: Int(settings.noiseLines)) {
                result = noise
                    .applyingFilter("CIAdditionCompositing", parameters: [
                        kCIInputBackgroundImageKey: result
                    ])
                    .cropped(to: extent)
            }
        }

        if settings.displacement > 0 {
            if let displaced = generateHorizontalDisplacement(base: result, extent: extent, scale: scale, seed: seed, maxShift: settings.displacement) {
                result = displaced
            }
        }

        if settings.grain > 0 {
            if let grain = generateGrain(size: extent.size, intensity: settings.grain, seed: seed) {
                result = grain
                    .applyingFilter("CIAdditionCompositing", parameters: [
                        kCIInputBackgroundImageKey: result
                    ])
                    .cropped(to: extent)
            }
        }

        if settings.microDistortion > 0 {
            result = applyMicroDistortion(to: result, extent: extent, scale: scale, seed: seed, intensity: settings.microDistortion)
        }

        if settings.vignette > 0 {
            let vignetteRadius = max(1.5, scale * 1.5)
            result = result.applyingFilter("CIVignette", parameters: [
                kCIInputIntensityKey: settings.vignette * 2.0,
                kCIInputRadiusKey: vignetteRadius
            ])
        }

        if settings.bloom > 0 {
            let bloomRadius = max(5.0, 8.0 * scale)
            result = result.applyingFilter("CIBloom", parameters: [
                kCIInputRadiusKey: bloomRadius,
                kCIInputIntensityKey: settings.bloom * 3.0
            ]).cropped(to: extent)
        }

        result = result.applyingFilter("CIGammaAdjust", parameters: [
            "inputPower": 0.96
        ])

        if settings.chromaticAberration > 0 {
            let aberration = settings.chromaticAberration

            let redOnly = result.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])
            let redShifted = redOnly.transformed(
                by: CGAffineTransform(translationX: CGFloat(aberration) * min(scale, 1.5) * 0.3, y: 0)
            )

            let greenOnly = result.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])

            let blueOnly = result.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])
            let blueShifted = blueOnly.transformed(
                by: CGAffineTransform(translationX: CGFloat(-aberration) * min(scale, 1.5) * 0.3, y: 0)
            )

            result = redShifted
                .applyingFilter("CIAdditionCompositing", parameters: [
                    kCIInputBackgroundImageKey: greenOnly
                ])
                .applyingFilter("CIAdditionCompositing", parameters: [
                    kCIInputBackgroundImageKey: blueShifted
                ])
                .cropped(to: extent)
        }

        if let stamp = generateDateStamp(size: extent.size, seed: seed) {
            result = stamp
                .applyingFilter("CISourceOverCompositing", parameters: [
                    kCIInputBackgroundImageKey: result
                ])
                .cropped(to: extent)
        }

        guard let outputCGImage = context.createCGImage(result, from: extent) else { return nil }
        return UIImage(cgImage: outputCGImage, scale: 1.0, orientation: .up)
    }

    nonisolated private static func generateScanlines(size: CGSize, scale: CGFloat, seed: UInt64, opacity: Double) -> CIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let lineSpacing = max(4.0, 2.0 * scale)
        let gapHeight = max(1.0, lineSpacing * 0.35)
        var rng = SeededRNG(seed: seed &+ 99999)

        let image = renderer.image { ctx in
            let gc = ctx.cgContext

            UIColor.white.setFill()
            gc.fill(CGRect(origin: .zero, size: size))

            var y: CGFloat = 0
            while y < size.height {
                let gapAlpha = CGFloat(opacity) * CGFloat.random(in: 0.7...1.0, using: &rng)
                gc.setFillColor(UIColor.black.withAlphaComponent(gapAlpha).cgColor)
                gc.fill(CGRect(x: 0, y: y, width: size.width, height: gapHeight))

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
                gc.fill(CGRect(x: 0, y: y + gapHeight, width: size.width, height: litRowHeight))

                if Bool.random(using: &rng) {
                    let wobbleAlpha = CGFloat(opacity) * CGFloat.random(in: 0.05...0.15, using: &rng)
                    gc.setFillColor(UIColor.white.withAlphaComponent(wobbleAlpha).cgColor)
                    gc.fill(CGRect(x: 0, y: y + gapHeight, width: size.width, height: litRowHeight))
                }

                y += lineSpacing
            }
        }
        guard let cgImage = image.cgImage else { return nil }
        return CIImage(cgImage: cgImage)
    }

    nonisolated private static func generateNoiseLines(size: CGSize, scale: CGFloat, seed: UInt64, lineCount: Int) -> CIImage? {
        guard lineCount > 0 else { return nil }
        var rng = SeededRNG(seed: seed)
        let renderer = UIGraphicsImageRenderer(size: size)
        let scaledUnit = max(1.0, scale * 0.8)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let gc = ctx.cgContext

            for _ in 0..<lineCount {
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let baseHeight = CGFloat.random(in: 3...8, using: &rng) * scaledUnit
                let alpha = CGFloat.random(in: 0.05...0.14, using: &rng)

                let blobCount = Int.random(in: 2...5, using: &rng)
                for _ in 0..<blobCount {
                    let blobX = CGFloat.random(in: -size.width * 0.1...0, using: &rng)
                    let blobWidth = CGFloat.random(in: size.width * 0.5...size.width * 1.2, using: &rng)
                    let blobY = y + CGFloat.random(in: -baseHeight * 0.3...baseHeight * 0.3, using: &rng)
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
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let height = CGFloat.random(in: 8...18, using: &rng) * scaledUnit
                let alpha = CGFloat.random(in: 0.03...0.08, using: &rng)

                gc.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                let rect = CGRect(x: 0, y: y, width: size.width, height: height)
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

    nonisolated private static func generateHorizontalDisplacement(base: CIImage, extent: CGRect, scale: CGFloat, seed: UInt64, maxShift: Double) -> CIImage? {
        var rng = SeededRNG(seed: seed &+ 12345)
        let bandCount = Int.random(in: 2...5, using: &rng)

        var result = base
        for _ in 0..<bandCount {
            let bandY = CGFloat.random(in: extent.origin.y...extent.origin.y + extent.height, using: &rng)
            let bandHeight = CGFloat.random(in: 4...14, using: &rng) * max(1, scale * 0.5)
            let shiftX = CGFloat.random(in: CGFloat(-maxShift)...CGFloat(maxShift), using: &rng) * max(1, scale * 0.8)

            let bandRect = CGRect(x: extent.origin.x, y: bandY, width: extent.width, height: bandHeight)
            let band = result.cropped(to: bandRect)
                .transformed(by: CGAffineTransform(translationX: shiftX, y: 0))
                .cropped(to: bandRect)

            result = band.applyingFilter("CISourceOverCompositing", parameters: [
                kCIInputBackgroundImageKey: result
            ]).cropped(to: extent)
        }

        return result
    }

    nonisolated private static func generateGrain(size: CGSize, intensity: Double, seed: UInt64) -> CIImage? {
        let extent = CGRect(origin: .zero, size: size)
        let scale = size.width / 1000.0

        guard let randomNoise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return nil }

        let noiseImage = randomNoise.cropped(to: extent)

        let lumaNoise = noiseImage.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,
            kCIInputBrightnessKey: -0.5,
            kCIInputContrastKey: 1.2
        ])

        let motionBlurRadius = max(4.0, 8.0 * scale)
        let horizontalLuma = lumaNoise.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: motionBlurRadius,
            kCIInputAngleKey: 0.0
        ]).cropped(to: extent)

        let lumaIntensity = intensity * 0.7
        let scaledLuma = horizontalLuma.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: CGFloat(lumaIntensity), y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: CGFloat(lumaIntensity), z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(lumaIntensity), w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])

        let chromaNoise = noiseImage.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 2.5,
            kCIInputBrightnessKey: -0.5,
            kCIInputContrastKey: 0.8
        ])

        let chromaBlurRadius = max(12.0, 25.0 * scale)
        let horizontalChroma = chromaNoise.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: chromaBlurRadius,
            kCIInputAngleKey: 0.0
        ]).cropped(to: extent)

        let chromaSmeared = horizontalChroma.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: max(2.0, 3.0 * scale),
            kCIInputAngleKey: Float.pi / 2.0
        ]).cropped(to: extent)

        let chromaIntensity = intensity * 0.35
        let scaledChroma = chromaSmeared.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: CGFloat(chromaIntensity), y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: CGFloat(chromaIntensity), z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: CGFloat(chromaIntensity), w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])

        var rng = SeededRNG(seed: seed &+ 77777)
        let renderer = UIGraphicsImageRenderer(size: size)
        let grainScale = max(1.0, scale * 0.6)

        let bandImage = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let gc = ctx.cgContext

            let bandCount = Int.random(in: 4...10, using: &rng)
            for _ in 0..<bandCount {
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let height = CGFloat.random(in: 8...30, using: &rng) * grainScale
                let alpha = CGFloat(intensity) * CGFloat.random(in: 0.06...0.15, using: &rng)

                let r = CGFloat.random(in: 0.3...0.45, using: &rng)
                let g = CGFloat.random(in: 0.3...0.4, using: &rng)
                let b = CGFloat.random(in: 0.45...0.6, using: &rng)
                gc.setFillColor(UIColor(red: r, green: g, blue: b, alpha: alpha).cgColor)
                gc.fill(CGRect(x: 0, y: y, width: size.width, height: height))
            }

            let dropoutCount = Int.random(in: 0...3, using: &rng)
            for _ in 0..<dropoutCount {
                let y = CGFloat.random(in: 0...size.height, using: &rng)
                let height = CGFloat.random(in: 1...2, using: &rng) * grainScale
                let x = CGFloat.random(in: 0...size.width * 0.5, using: &rng)
                let width = CGFloat.random(in: size.width * 0.05...size.width * 0.4, using: &rng)
                let alpha = CGFloat(intensity) * CGFloat.random(in: 0.15...0.35, using: &rng)

                gc.setFillColor(UIColor(white: 0.8, alpha: alpha).cgColor)
                gc.fill(CGRect(x: x, y: y, width: width, height: height))
            }
        }
        guard let bandCGImage = bandImage.cgImage else { return nil }
        let bandCI = CIImage(cgImage: bandCGImage)

        let combined = scaledLuma
            .applyingFilter("CIAdditionCompositing", parameters: [
                kCIInputBackgroundImageKey: scaledChroma
            ])
            .applyingFilter("CIAdditionCompositing", parameters: [
                kCIInputBackgroundImageKey: bandCI
            ])
            .cropped(to: extent)

        return combined
    }

    nonisolated private static func applyMicroDistortion(to image: CIImage, extent: CGRect, scale: CGFloat, seed: UInt64, intensity: Double) -> CIImage {
        // Grain-level horizontal distortion — individual noise grains each
        // shift nearby pixels horizontally, giving a gritty, degraded look.
        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return image }

        let greyNoise = noise.cropped(to: extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputBrightnessKey: -0.5,
                kCIInputContrastKey: 1.5
            ])

        // Slight horizontal smear so each grain stretches a few pixels wide,
        // biasing the displacement horizontally without merging entire rows.
        let hBlurRadius = max(2.0, 4.0 * scale)
        let smearedNoise = greyNoise.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: hBlurRadius,
            kCIInputAngleKey: 0.0
        ]).cropped(to: extent)

        // intensity 1.0 → ~6px shift at 640px wide
        let displacementScale = CGFloat(intensity) * 6.0 * max(1.0, scale)

        let distorted = image.applyingFilter("CIDisplacementDistortion", parameters: [
            "inputDisplacementImage": smearedNoise,
            kCIInputScaleKey: displacementScale
        ]).cropped(to: extent)

        return distorted
    }

    nonisolated private static func generateDateStamp(size: CGSize, seed: UInt64) -> CIImage? {
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
            let font = UIFont(name: "Courier", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)

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
            let playFont = UIFont(name: "Courier-Bold", size: fontSize * 0.9) ?? UIFont.monospacedSystemFont(ofSize: fontSize * 0.9, weight: .bold)
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

nonisolated struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
