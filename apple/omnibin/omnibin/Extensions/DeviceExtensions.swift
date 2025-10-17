import SwiftUI
import UIKit

// MARK: - Device Detection Extensions
extension View {
    /// Returns true if the current device is an iPad
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

// MARK: - Font Size Helpers for iPad
extension View {
    /// Returns the appropriate font size for iPad (50% larger) or default for other devices
    func ipadFontSize(_ defaultSize: CGFloat) -> CGFloat {
        isIPad ? defaultSize * 1.5 : defaultSize
    }
}
