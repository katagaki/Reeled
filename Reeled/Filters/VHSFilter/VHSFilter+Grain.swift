import CoreImage
import UIKit

extension VHSFilter {

    // Zero-mean tape noise: one field adds, an independent one subtracts
    // swiftlint:disable:next function_body_length
    nonisolated static func applyGrain(
        to image: CIImage,
        extent: CGRect,
        intensity: Double,
        seed: UInt64
    ) -> CIImage {
        guard let randomNoise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return image }
        let scale = extent.width / 1000.0

        var rng = SeededRNG(seed: seed &+ 33333)

        // CIRandomGenerator randomises alpha too — force each sample opaque
        func noiseField() -> CIImage {
            let offsetX = CGFloat(rng.next() % 10000)
            let offsetY = CGFloat(rng.next() % 10000)
            return randomNoise
                .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
                .cropped(to: extent)
                .settingAlphaOne(in: extent)
        }

        func lumaStreaked(_ noise: CIImage) -> CIImage {
            noise.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputBrightnessKey: 0.0,
                kCIInputContrastKey: 1.0
            ]).applyingFilter("CIMotionBlur", parameters: [
                kCIInputRadiusKey: max(2.0, 4.0 * scale),
                kCIInputAngleKey: 0.0
            ]).cropped(to: extent)
        }

        func chromaStreaked(_ noise: CIImage) -> CIImage {
            noise.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 3.0,
                kCIInputBrightnessKey: 0.0,
                kCIInputContrastKey: 1.0
            ]).applyingFilter("CIMotionBlur", parameters: [
                kCIInputRadiusKey: max(12.0, 22.0 * scale),
                kCIInputAngleKey: 0.0
            ]).cropped(to: extent)
            .applyingFilter("CIMotionBlur", parameters: [
                kCIInputRadiusKey: max(2.0, 3.0 * scale),
                kCIInputAngleKey: Float.pi / 2.0
            ]).cropped(to: extent)
        }

        func gain(_ noise: CIImage, _ amount: CGFloat) -> CIImage {
            noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: amount, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: amount, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: amount, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
            ])
        }

        func inverseGain(_ noise: CIImage, _ amount: CGFloat) -> CIImage {
            noise.applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: -amount, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: -amount, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: -amount, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 1, y: 1, z: 1, w: 0)
            ])
        }

        let lumaAmount = CGFloat(intensity) * 0.5
        let chromaAmount = CGFloat(intensity) * 0.2

        var result = image
        result = gain(lumaStreaked(noiseField()), lumaAmount)
            .applyingFilter("CILinearDodgeBlendMode", parameters: [
                kCIInputBackgroundImageKey: result
            ]).cropped(to: extent)
        result = inverseGain(lumaStreaked(noiseField()), lumaAmount)
            .applyingFilter("CILinearBurnBlendMode", parameters: [
                kCIInputBackgroundImageKey: result
            ]).cropped(to: extent)
        result = gain(chromaStreaked(noiseField()), chromaAmount)
            .applyingFilter("CILinearDodgeBlendMode", parameters: [
                kCIInputBackgroundImageKey: result
            ]).cropped(to: extent)
        result = inverseGain(chromaStreaked(noiseField()), chromaAmount)
            .applyingFilter("CILinearBurnBlendMode", parameters: [
                kCIInputBackgroundImageKey: result
            ]).cropped(to: extent)

        return result
    }
}
