import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct VHSFilter: Sendable {

    nonisolated static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// VHS horizontal resolution was ~320 lines mapped to a 4:3 frame.
    /// We use 640x480 as a recognisable doubled-up VHS frame size.
    nonisolated static let vhsLongEdge: CGFloat = 640
    nonisolated static let vhsShortEdge: CGFloat = 480

    nonisolated static func apply(to image: UIImage, settings: VHSFilterSettings.Snapshot) -> UIImage? {
        guard let ciImage = cropAndScale(image: image) else { return nil }
        let extent = ciImage.extent
        let seed = UInt64.random(in: 0...UInt64.max)
        let scale = extent.width / 1000.0

        var result = applyColorCorrection(to: ciImage, extent: extent, scale: scale, settings: settings)
        result = applyTextureEffects(to: result, extent: extent, scale: scale, seed: seed, settings: settings)
        result = applyAtmosphereEffects(to: result, extent: extent, scale: scale, settings: settings)

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

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    nonisolated static func applyTextureEffects(
        to image: CIImage, extent: CGRect, scale: CGFloat,
        seed: UInt64, settings: VHSFilterSettings.Snapshot
    ) -> CIImage {
        var result = image

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
            if let scanlines = generateScanlines(
                size: extent.size, scale: scale,
                seed: seed, opacity: settings.scanlineOpacity
            ) {
                result = scanlines
                    .applyingFilter("CIMultiplyCompositing", parameters: [
                        kCIInputBackgroundImageKey: result
                    ])
                    .cropped(to: extent)
            }
        }

        if settings.noiseLines > 0 {
            if let noise = generateNoiseLines(
                size: extent.size, scale: scale,
                seed: seed, lineCount: Int(settings.noiseLines)
            ) {
                result = noise
                    .applyingFilter("CIAdditionCompositing", parameters: [
                        kCIInputBackgroundImageKey: result
                    ])
                    .cropped(to: extent)
            }
        }

        if settings.displacement > 0 {
            if let displaced = generateHorizontalDisplacement(
                base: result, extent: extent, scale: scale,
                seed: seed, maxShift: settings.displacement
            ) {
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
            result = applyMicroDistortion(
                to: result, extent: extent, scale: scale,
                seed: seed, intensity: settings.microDistortion
            )
        }

        return result
    }

    nonisolated static func applyAtmosphereEffects(
        to image: CIImage, extent: CGRect, scale: CGFloat,
        settings: VHSFilterSettings.Snapshot
    ) -> CIImage {
        var result = image

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
            result = applyChromaticAberration(
                to: result, extent: extent, scale: scale,
                amount: settings.chromaticAberration
            )
        }

        return result
    }
}
