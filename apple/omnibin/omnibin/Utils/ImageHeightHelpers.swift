import UIKit

// MARK: - Device Detection
private var isIPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

// MARK: - Image Height Constants
var minIdealImageHeight: CGFloat {
    isIPad ? 250 : 100
}

var maxIdealImageHeight: CGFloat {
    isIPad ? 1000 : 425
}

var defaultImageHeight: CGFloat {
    isIPad ? 500 : 200
}

// MARK: - Image Height Calculation
func getIdealImageHeight(for image: UIImage, containerWidth: CGFloat? = nil) -> CGFloat {
    let imageWidth = image.size.width
    let imageHeight = image.size.height
    
    guard imageWidth > 0 else { return defaultImageHeight }
    
    // Use provided container width, or fallback to screen width with more conservative padding
    let availableWidth: CGFloat
    if let containerWidth = containerWidth {
        availableWidth = containerWidth
    } else {
        // Account for more padding: 2px border + potential margins
        availableWidth = UIScreen.main.bounds.width - 32
    }
    
    let aspectRatio = imageHeight / imageWidth
    let desiredHeight = availableWidth * aspectRatio
    
    // Clamp between min and max
    return min(max(desiredHeight, minIdealImageHeight), maxIdealImageHeight)
}

