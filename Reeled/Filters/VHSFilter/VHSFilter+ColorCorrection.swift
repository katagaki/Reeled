import CoreImage
import UIKit

extension VHSFilter {

    nonisolated static func applyColorCorrection(
        to image: CIImage,
        extent: CGRect,
        scale: CGFloat,
        settings: VHSFilterSettings.Snapshot
    ) -> CIImage {
        var result = image.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: settings.saturation,
            kCIInputBrightnessKey: settings.brightness,
            kCIInputContrastKey: settings.contrast
        ])
        result = result.applyingFilter("CITemperatureAndTint", parameters: [
            "inputNeutral": CIVector(x: 5800, y: 0),
            "inputTargetNeutral": CIVector(x: settings.warmth, y: 25)
        ])

        // Analog levels: lifted blacks, soft-clipped whites
        result = result.applyingFilter("CIToneCurve", parameters: [
            "inputPoint0": CIVector(x: 0.0, y: 0.025),
            "inputPoint1": CIVector(x: 0.25, y: 0.26),
            "inputPoint2": CIVector(x: 0.5, y: 0.5),
            "inputPoint3": CIVector(x: 0.75, y: 0.75),
            "inputPoint4": CIVector(x: 1.0, y: 0.965)
        ])

        // Chroma bleed: blur and delay the colour, keep the luma sharp
        let chromaBlurRadius = max(6.0, 12.0 * scale)
        var chroma = result.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: chromaBlurRadius,
            kCIInputAngleKey: 0.0
        ]).cropped(to: extent)
        chroma = chroma.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: max(1.0, 1.5 * scale),
            kCIInputAngleKey: Float.pi / 2.0
        ]).cropped(to: extent)
        chroma = chroma
            .transformed(by: CGAffineTransform(translationX: max(1.0, 2.0 * scale), y: 0))
            .clampedToExtent()
            .cropped(to: extent)

        // CIColorBlendMode: background luminance + source hue/saturation
        return chroma.applyingFilter("CIColorBlendMode", parameters: [
            kCIInputBackgroundImageKey: result
        ]).cropped(to: extent)
    }

    nonisolated static func applyChromaticAberration(
        to image: CIImage,
        extent: CGRect,
        scale: CGFloat,
        amount: Double
    ) -> CIImage {
        let redOnly = image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
        let redShifted = redOnly.transformed(
            by: CGAffineTransform(translationX: CGFloat(amount) * min(scale, 1.5) * 0.3, y: 0)
        )

        let greenOnly = image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])

        let blueOnly = image.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
        let blueShifted = blueOnly.transformed(
            by: CGAffineTransform(translationX: CGFloat(-amount) * min(scale, 1.5) * 0.3, y: 0)
        )

        // Maximum compositing reassembles the planes without stacking alpha
        return redShifted
            .applyingFilter("CIMaximumCompositing", parameters: [
                kCIInputBackgroundImageKey: greenOnly
            ])
            .applyingFilter("CIMaximumCompositing", parameters: [
                kCIInputBackgroundImageKey: blueShifted
            ])
            .cropped(to: extent)
    }
}
