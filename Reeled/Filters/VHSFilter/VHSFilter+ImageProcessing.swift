import CoreImage
import UIKit

extension VHSFilter {

    nonisolated static func cropAndScale(image: UIImage) -> CIImage? {
        let normalizedImage = image.normalizedOrientation()
        guard let original = CIImage(image: normalizedImage) else { return nil }

        let srcW = original.extent.width
        let srcH = original.extent.height
        let isLandscape = srcW >= srcH
        let targetW: CGFloat = isLandscape ? vhsLongEdge : vhsShortEdge
        let targetH: CGFloat = isLandscape ? vhsShortEdge : vhsLongEdge
        let targetAspect = targetW / targetH

        let srcAspect = srcW / srcH
        let cropRect: CGRect
        if srcAspect > targetAspect {
            let cropW = srcH * targetAspect
            cropRect = CGRect(x: (srcW - cropW) / 2, y: 0, width: cropW, height: srcH)
        } else {
            let cropH = srcW / targetAspect
            cropRect = CGRect(x: 0, y: (srcH - cropH) / 2, width: srcW, height: cropH)
        }
        let cropped = original.cropped(to: cropRect)

        let scaleX = targetW / cropped.extent.width
        let scaleY = targetH / cropped.extent.height
        let scaled = cropped.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        return scaled.transformed(by: CGAffineTransform(
            translationX: -scaled.extent.origin.x, y: -scaled.extent.origin.y
        ))
    }
}
