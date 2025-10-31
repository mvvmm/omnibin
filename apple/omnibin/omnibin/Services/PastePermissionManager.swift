import Foundation

class PastePermissionManager {
    static let shared = PastePermissionManager()
    
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
        return !hasShownPopup()
    }
}
