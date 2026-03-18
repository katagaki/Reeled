import UIKit

extension UIImage {
    // swiftlint:disable cyclomatic_complexity
    /// Redraws the image so that `.imageOrientation` is `.up`, baking in any
    /// EXIF rotation. This prevents CIImage from treating portrait photos as
    /// landscape (or vice versa).
    nonisolated func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        guard let cgImage = cgImage else { return self }

        let width = Int(size.width)
        let height = Int(size.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }

        // Apply the transform that UIImage uses to compensate for orientation
        var transform = CGAffineTransform.identity
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: CGFloat(width), y: CGFloat(height))
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: CGFloat(width), y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: CGFloat(height))
            transform = transform.rotated(by: -.pi / 2)
        default: break
        }

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: CGFloat(width), y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: CGFloat(height), y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default: break
        }

        ctx.concatenate(transform)

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: height, height: width))
        default:
            ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        guard let normalizedCG = ctx.makeImage() else { return self }
        return UIImage(cgImage: normalizedCG, scale: scale, orientation: .up)
    }
    // swiftlint:enable cyclomatic_complexity
}
