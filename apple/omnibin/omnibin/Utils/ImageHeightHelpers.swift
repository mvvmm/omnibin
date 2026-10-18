import CoreGraphics

// MARK: - Image Height Constants
var minIdealImageHeight: CGFloat = 100
var maxIdealImageHeight: CGFloat {
    isIPad ? 800 : 400
}
var defaultImageHeight: CGFloat {
    isIPad ? 400 : 200
}
