import UIKit

// Helper class to handle UIImageWriteToSavedPhotosAlbum completion callback
class ImageSaveHandler: NSObject {
    var completion: (Error?) -> Void
    
    init(completion: @escaping (Error?) -> Void) {
        self.completion = completion
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completion(error)
    }
}
