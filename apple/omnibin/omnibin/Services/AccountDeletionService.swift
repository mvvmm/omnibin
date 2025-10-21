import Foundation

// MARK: - Account Deletion Service
class AccountDeletionService {
    static let shared = AccountDeletionService()
    
    private let networkConfig = NetworkConfiguration.shared
    
    private init() {}
    
    // MARK: - Account Deletion
    
    func deleteAccount(accessToken: String) async throws -> Bool {
        guard let url = URL(string: "\(networkConfig.baseURL)/api/account/delete") else {
            throw AccountDeletionError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await networkConfig.createURLSession().data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AccountDeletionError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            return true
        } else {
            // Try to parse error message from response
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw AccountDeletionError.serverError(errorMessage)
            } else {
                throw AccountDeletionError.serverError("Account deletion failed with status \(httpResponse.statusCode)")
            }
        }
    }
}

// MARK: - Account Deletion Errors
enum AccountDeletionError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for account deletion"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return message
        }
    }
}
