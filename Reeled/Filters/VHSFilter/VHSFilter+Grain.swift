import CoreImage
import UIKit

extension VHSFilter {

    // swiftlint:disable:next function_body_length
    nonisolated static func generateGrain(
        size: CGSize,
        intensity: Double,
        seed: UInt64
    ) -> CIImage? {
        let extent = CGRect(origin: .zero, size: size)
        let scale = size.width / 1000.0

        guard let randomNoise = CIFilter(name: "CIRandomGenerator")?.outputImage else { return nil }

        // Offset into the infinite noise texture using the seed so each
        // call samples a different region, producing unique grain.
        var rng = SeededRNG(seed: seed &+ 33333)
        let offsetX = CGFloat(rng.next() % 10000)
        let offsetY = CGFloat(rng.next() % 10000)
        let noiseImage = randomNoise
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            .cropped(to: extent)

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

        var bandRng = SeededRNG(seed: seed &+ 77777)
        let renderer = UIGraphicsImageRenderer(size: size)
        let grainScale = max(1.0, scale * 0.6)

        let bandImage = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let gc = ctx.cgContext

            let bandCount = Int.random(in: 4...10, using: &bandRng)
            for _ in 0..<bandCount {
                let bandY = CGFloat.random(in: 0...size.height, using: &bandRng)
                let height = CGFloat.random(in: 8...30, using: &bandRng) * grainScale
                let alpha = CGFloat(intensity) * CGFloat.random(in: 0.06...0.15, using: &bandRng)

                let red = CGFloat.random(in: 0.3...0.45, using: &bandRng)
                let grn = CGFloat.random(in: 0.3...0.4, using: &bandRng)
                let blu = CGFloat.random(in: 0.45...0.6, using: &bandRng)
                gc.setFillColor(UIColor(red: red, green: grn, blue: blu, alpha: alpha).cgColor)
                gc.fill(CGRect(x: 0, y: bandY, width: size.width, height: height))
            }

            let dropoutCount = Int.random(in: 0...3, using: &bandRng)
            for _ in 0..<dropoutCount {
                let dropY = CGFloat.random(in: 0...size.height, using: &bandRng)
                let height = CGFloat.random(in: 1...2, using: &bandRng) * grainScale
                let dropX = CGFloat.random(in: 0...size.width * 0.5, using: &bandRng)
                let width = CGFloat.random(in: size.width * 0.05...size.width * 0.4, using: &bandRng)
                let alpha = CGFloat(intensity) * CGFloat.random(in: 0.15...0.35, using: &bandRng)

                gc.setFillColor(UIColor(white: 0.8, alpha: alpha).cgColor)
                gc.fill(CGRect(x: dropX, y: dropY, width: width, height: height))
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
}
