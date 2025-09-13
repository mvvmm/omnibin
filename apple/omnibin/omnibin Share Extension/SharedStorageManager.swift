import Foundation

class SharedStorageManager {
    static let shared = SharedStorageManager()
    
    private let groupIdentifier = "group.in.omnib.omnibin"
    private let accessTokenKey = "access_token"
    
    private init() {}
    
    // MARK: - Access Token Management
    
    func getAccessToken() -> String? {
        guard let sharedDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return nil
        }
        return sharedDefaults.string(forKey: accessTokenKey)
    }
    
    func setAccessToken(_ token: String) {
        guard let sharedDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return
        }
        sharedDefaults.set(token, forKey: accessTokenKey)
    }
    
    func clearAccessToken() {
        guard let sharedDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return
        }
        sharedDefaults.removeObject(forKey: accessTokenKey)
    }
    
    // MARK: - User Info Management
    
    func getUserInfo() -> [String: Any]? {
        guard let sharedDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return nil
        }
        return sharedDefaults.dictionary(forKey: "user_info")
    }
    
    func setUserInfo(_ userInfo: [String: Any]) {
        guard let sharedDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return
        }
        sharedDefaults.set(userInfo, forKey: "user_info")
    }
    
    func clearUserInfo() {
        guard let sharedDefaults = UserDefaults(suiteName: groupIdentifier) else {
            return
        }
        sharedDefaults.removeObject(forKey: "user_info")
    }
}
