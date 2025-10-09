import Foundation
import Auth0

// MARK: - Main View Authentication Service
@MainActor
class MainViewAuthService: ObservableObject {
    @Published var user: User?
    @Published var accessToken: String?
    @Published var isLoading = true
    
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    init() {}
    
    // MARK: - Public Methods
    
    func checkStoredCredentials() {
        credentialsManager.credentials { result in
            Task { @MainActor in
                switch result {
                case .success(let credentials):
                    self.user = User(from: credentials.idToken)
                    self.accessToken = credentials.accessToken
                    self.isLoading = false
                case .failure(_):
                    // Try to renew if we have stored credentials but they're expired
                    if self.credentialsManager.canRenew() {
                        self.credentialsManager.renew { renewResult in
                            Task { @MainActor in
                                switch renewResult {
                                case .success(let renewedCredentials):
                                    self.user = User(from: renewedCredentials.idToken)
                                    self.accessToken = renewedCredentials.accessToken
                                    
                                    // Update access token in shared Keychain
                                    SecureStorageManager.shared.setAccessToken(renewedCredentials.accessToken)
                                    
                                    // Also store in UserDefaults for debugging
                                    if let sharedDefaults = UserDefaults(suiteName: "group.in.omnib.omnibin") {
                                        sharedDefaults.set(renewedCredentials.accessToken, forKey: "access_token")
                                    }
                                    
                                    self.isLoading = false
                                case .failure(_):
                                    self.isLoading = false
                                }
                            }
                        }
                    } else {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func login() {
        Auth0
            .webAuth()
            .useHTTPS() // Use a Universal Link callback URL on iOS 17.4+ / macOS 14.4+
            .audience("https://omnib.in/api")
            .scope("openid profile email offline_access")
            .start { result in
                Task { @MainActor in
                    switch result {
                    case .success(let credentials):
                        // Store credentials for future use
                        _ = self.credentialsManager.store(credentials: credentials)
                        self.user = User(from: credentials.idToken)
                        self.accessToken = credentials.accessToken
                        
                        // Store access token in shared Keychain for Share Extension
                        SecureStorageManager.shared.setAccessToken(credentials.accessToken)
                        
                        // Also store in UserDefaults for debugging
                        if let sharedDefaults = UserDefaults(suiteName: "group.in.omnib.omnibin") {
                            sharedDefaults.set(credentials.accessToken, forKey: "access_token")
                        }
                        
                        self.isLoading = false
                    case .failure(_):
                        self.isLoading = false
                    }
                }
            }
    }
    
    func logout() {
        // Clear stored credentials
        _ = credentialsManager.clear()
        
        // Clear shared Keychain
        SecureStorageManager.shared.deleteAccessToken()
        SecureStorageManager.shared.clearUserInfo()
        
        Auth0
            .webAuth()
            .useHTTPS() // Use a Universal Link logout URL on iOS 17.4+ / macOS 14.4+
            .clearSession { result in
                Task { @MainActor in
                    switch result {
                    case .success:
                        self.user = nil
                        self.accessToken = nil
                        self.isLoading = false
                    case .failure(_):
                        self.isLoading = false
                    }
                }
            }
    }
}
