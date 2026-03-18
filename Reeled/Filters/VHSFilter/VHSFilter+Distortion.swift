import CoreImage
import UIKit

extension VHSFilter {

    nonisolated static func generateHorizontalDisplacement(
        base: CIImage,
        extent: CGRect,
        scale: CGFloat,
        seed: UInt64,
        maxShift: Double
    ) -> CIImage? {
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

    nonisolated static func applyMicroDistortion(
        to image: CIImage,
        extent: CGRect,
        scale: CGFloat,
        seed: UInt64,
        intensity: Double
    ) -> CIImage {
        guard let noise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return image }

        var rng = SeededRNG(seed: seed &+ 55555)
        let offsetX = CGFloat(rng.next() % 10000)
        let offsetY = CGFloat(rng.next() % 10000)
        let shiftedNoise = noise
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))

        let greyNoise = shiftedNoise.cropped(to: extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputBrightnessKey: -0.5,
                kCIInputContrastKey: 1.5
            ])

        let hBlurRadius = max(2.0, 4.0 * scale)
        let smearedNoise = greyNoise.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: hBlurRadius,
            kCIInputAngleKey: 0.0
        ]).cropped(to: extent)

        let displacementScale = CGFloat(intensity) * 6.0 * max(1.0, scale)

        let distorted = image.applyingFilter("CIDisplacementDistortion", parameters: [
            "inputDisplacementImage": smearedNoise,
            kCIInputScaleKey: displacementScale
        ]).cropped(to: extent)

        return distorted
    }
}
