import UIKit

// MARK: - Image Height Constants
var minIdealImageHeight: CGFloat = 100
var maxIdealImageHeight: CGFloat {
    isIPad ? 800 : 400
}
var defaultImageHeight: CGFloat {
    isIPad ? 400 : 200
}

// MARK: - Image Height Calculation
func getIdealImageHeight(for image: UIImage, containerWidth: CGFloat? = nil) -> CGFloat {
    let imageWidth = image.size.width
    let imageHeight = image.size.height
    
    guard imageWidth > 0, imageHeight > 0 else { return defaultImageHeight }
    
    // Use provided container width, or fallback to screen width with more conservative padding
    let availableWidth: CGFloat
    if let containerWidth = containerWidth {
        availableWidth = containerWidth
    } else {
        let screenWidth = UIScreen.main.bounds.width
        let basePadding: CGFloat = 32 // Horizontal padding
        
        if isTwoColumn {
            // In two-column mode: divide width by 2 and account for spacing between columns
            let columnSpacing: CGFloat = 12
            availableWidth = (screenWidth - basePadding - columnSpacing) / 2
        } else {
            // Single column mode
            availableWidth = screenWidth - basePadding
        }
    }
    
    let aspectRatio = imageHeight / imageWidth
    let desiredHeight = availableWidth * aspectRatio
    
    // Clamp to maximum height first
    var finalHeight = min(desiredHeight, maxIdealImageHeight)
    
    // Only apply minimum height if it won't cause the image to exceed available width
    // Calculate what width would be needed for the minimum height
    let widthNeededForMinHeight = minIdealImageHeight / aspectRatio
    
    if finalHeight < minIdealImageHeight && widthNeededForMinHeight <= availableWidth {
        // Safe to use minimum height - image won't be clipped horizontally
        finalHeight = minIdealImageHeight
    }
    // Otherwise, use the calculated height to ensure image fits width properly
    
    return finalHeight
}

