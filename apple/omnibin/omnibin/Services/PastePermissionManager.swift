import Foundation

class PastePermissionManager {
    static let shared = PastePermissionManager()
    
    // Debug flag: if true, always show the settings popup regardless of whether it's been shown before
    private let ALWAYS_SHOW_SETTINGS_POPUP = false
    
    private let hasShownPopupKey = "hasShownPastePermissionPopup"
    
    private init() {}
    
    // MARK: - Popup Management
    
    func hasShownPopup() -> Bool {
        return UserDefaults.standard.bool(forKey: hasShownPopupKey)
    }
    
    func markPopupAsShown() {
        UserDefaults.standard.set(true, forKey: hasShownPopupKey)
    }
    
    func shouldShowPopup() -> Bool {
        // If debug flag is enabled, always show the popup
        if ALWAYS_SHOW_SETTINGS_POPUP {
            return true
        }
        return !hasShownPopup()
    }
}
