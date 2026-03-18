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
        let chromaBleedRadius = max(1.5, 3.0 * scale)
        let blurredForChroma = result.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: chromaBleedRadius,
            kCIInputAngleKey: 0.0
        ]).cropped(to: extent)
        return result.applyingFilter("CIColorBlendMode", parameters: [
            kCIInputBackgroundImageKey: blurredForChroma
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

        return redShifted
            .applyingFilter("CIAdditionCompositing", parameters: [
                kCIInputBackgroundImageKey: greenOnly
            ])
            .applyingFilter("CIAdditionCompositing", parameters: [
                kCIInputBackgroundImageKey: blueShifted
            ])
            .cropped(to: extent)
    }
}
