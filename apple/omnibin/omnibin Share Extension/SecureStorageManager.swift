import Foundation
import Security

class SecureStorageManager {
    static let shared = SecureStorageManager()
    
    private let groupIdentifier = "group.in.omnib.omnibin"
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    private init() {}

    // MARK: - Keychain Access Token Management
    
    func getAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "omnibin_access_token",
            kSecAttrAccessGroup as String: groupIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func setAccessToken(_ token: String) {
        // First, delete any existing token
        deleteAccessToken()
        
        guard let data = token.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "omnibin_access_token",
            kSecAttrAccessGroup as String: groupIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func deleteAccessToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "omnibin_access_token",
            kSecAttrAccessGroup as String: groupIdentifier
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Keychain Refresh Token Management

    func getRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "omnibin_refresh_token",
            kSecAttrAccessGroup as String: groupIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func setRefreshToken(_ token: String) {
        // First, delete any existing token
        deleteRefreshToken()

        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "omnibin_refresh_token",
            kSecAttrAccessGroup as String: groupIdentifier,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func deleteRefreshToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "omnibin_refresh_token",
            kSecAttrAccessGroup as String: groupIdentifier
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - User Info Management (can use UserDefaults for non-sensitive data)
    
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
