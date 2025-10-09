import Foundation
import Auth0

// MARK: - Authentication Service
class AuthenticationService {
    static let shared = AuthenticationService()
    
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    private init() {}
    
    // MARK: - Token Refresh
    func refreshTokenIfNeeded() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.credentialsManager.credentials { result in
                switch result {
                case .success(let credentials):
                    continuation.resume(returning: credentials.accessToken)
                case .failure(let error):
                    // Try to renew if we have stored credentials but they're expired
                    if self.credentialsManager.canRenew() {
                        self.credentialsManager.renew { renewResult in
                            switch renewResult {
                            case .success(let renewedCredentials):
                                continuation.resume(returning: renewedCredentials.accessToken)
                            case .failure(let renewError):
                                continuation.resume(throwing: renewError)
                            }
                        }
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    // MARK: - Token Validation
    func validateToken(_ token: String) -> Bool {
        return !token.isEmpty
    }
}
