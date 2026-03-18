import UIKit

class ImageSaver: NSObject {
    private var onSuccess: () -> Void
    private var onError: (Error) -> Void

    init(onSuccess: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }

    func save(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(handleResult(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }

    @objc private func handleResult(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        if let error {
            onError(error)
        } else {
            onSuccess()
        }
    }
}
