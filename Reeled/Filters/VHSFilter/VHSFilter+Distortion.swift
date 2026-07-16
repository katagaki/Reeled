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

        var result = base

        // Tracking tears: thin slices shifted along the line
        let bandCount = Int.random(in: 1...3, using: &rng)
        for _ in 0..<bandCount {
            let bandY = CGFloat.random(in: extent.minY...extent.maxY, using: &rng)
            let bandHeight = CGFloat.random(in: 2...7, using: &rng) * max(1, scale * 0.6)
            let shiftX = CGFloat.random(in: CGFloat(-maxShift)...CGFloat(maxShift), using: &rng) * max(1, scale * 0.8)

            let bandRect = CGRect(x: extent.origin.x, y: bandY, width: extent.width, height: bandHeight)
            let band = result.cropped(to: bandRect)
                .transformed(by: CGAffineTransform(translationX: shiftX, y: 0))
                .clampedToExtent()
                .cropped(to: bandRect)

            result = band.applyingFilter("CISourceOverCompositing", parameters: [
                kCIInputBackgroundImageKey: result
            ]).cropped(to: extent)
        }

        // Head-switching band at the very bottom of the frame
        let switchHeight = (max(4.0, extent.height * 0.018)).rounded()
        let direction: CGFloat = Bool.random(using: &rng) ? 1 : -1
        let switchShift = direction * (CGFloat(maxShift) * 1.2 + 2.0) * max(1, scale * 0.8)
        let switchRect = CGRect(x: extent.minX, y: extent.minY, width: extent.width, height: switchHeight)
        let switchBand = result.cropped(to: switchRect)
            .transformed(by: CGAffineTransform(translationX: switchShift, y: 0))
            .clampedToExtent()
            .applyingFilter("CIMotionBlur", parameters: [
                kCIInputRadiusKey: max(1.5, 2.0 * scale),
                kCIInputAngleKey: 0.0
            ])
            .cropped(to: switchRect)

        result = switchBand.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: result
        ]).cropped(to: extent)

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

        // Time-base error: per-row map so whole scanlines jitter horizontally
        let stripRect = CGRect(x: 0, y: extent.minY - 8, width: 8, height: extent.height + 16)
        let strip = noise
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            .cropped(to: stripRect)
            .settingAlphaOne(in: stripRect)
        let smoothed = strip.applyingFilter("CIMotionBlur", parameters: [
            kCIInputRadiusKey: 3.0,
            kCIInputAngleKey: Float.pi / 2.0
        ])
        let column = smoothed
            .cropped(to: CGRect(x: 3, y: extent.minY, width: 1, height: extent.height))
            .samplingNearest()
            .transformed(by: CGAffineTransform(translationX: -3, y: 0))
        let stretched = column
            .transformed(by: CGAffineTransform(scaleX: extent.width, y: 1))
            .cropped(to: extent)

        // Red drives x; green pinned to 0.5 zeroes the vertical offset
        let map = stretched.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: 0, y: 0.5, z: 0.5, w: 0)
        ]).cropped(to: extent)

        let displacementScale = CGFloat(intensity) * 5.0 * max(1.0, scale)

        let distorted = image
            .clampedToExtent()
            .applyingFilter("CIDisplacementDistortion", parameters: [
                "inputDisplacementImage": map,
                kCIInputScaleKey: displacementScale
            ])
            .cropped(to: extent)

        return distorted
    }
}
