import UIKit
import Photos

@MainActor
class ImageService: ObservableObject {
    
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Error?) -> Void) {
        let handler = ImageSaveHandler { error in
            completion(error)
        }
        UIImageWriteToSavedPhotosAlbum(image, handler, #selector(ImageSaveHandler.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func checkPhotosPermission() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    func requestPhotosPermission() async -> PHAuthorizationStatus {
        return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
}
