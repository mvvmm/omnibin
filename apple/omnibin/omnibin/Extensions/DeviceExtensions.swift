import SwiftUI
import UIKit

// MARK: - Device Detection Extensions
extension View {
    /// Returns true if the current device is an iPad
    var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Returns true if the current device should use two-column layout (iPad with width >= 900)
    var isTwoColumn: Bool {
        UIDevice.current.userInterfaceIdiom == .pad && UIScreen.main.bounds.width >= 900
    }
}

// MARK: - Global Device Detection Helpers
/// Returns true if the current device is an iPad
var isIPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}

/// Returns true if the current device should use two-column layout (iPad with width >= 900)
var isTwoColumn: Bool {
    UIDevice.current.userInterfaceIdiom == .pad && UIScreen.main.bounds.width >= 900
}

// MARK: - Font Size Helpers for iPad
extension View {
    /// Returns the appropriate font size for iPad (50% larger) or default for other devices
    func ipadFontSize(_ defaultSize: CGFloat) -> CGFloat {
        isIPad ? defaultSize * 1.5 : defaultSize
    }
}
