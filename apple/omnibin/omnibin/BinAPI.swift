import Foundation
import Auth0

class BinAPI: ObservableObject {
    static let shared = BinAPI()
    
    private let baseURL = "https://www.omnib.in" // Use the full domain
    private let binEndpoint = "/api/bin"
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
    private init() {}
    
    // MARK: - Token Refresh
    private func refreshTokenIfNeeded() async throws -> String {
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
    
    // MARK: - Fetch Bin Items
    func fetchBinItems(accessToken: String) async throws -> [BinItem] {
        do {
            return try await performFetchBinItems(accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await refreshTokenIfNeeded()
            return try await performFetchBinItems(accessToken: refreshedToken)
        }
    }
    
    private func performFetchBinItems(accessToken: String) async throws -> [BinItem] {
        guard !accessToken.isEmpty else {
            throw BinAPIError.httpError(401, message: "No access token provided")
        }
        
        guard let url = URL(string: baseURL + binEndpoint) else {
            throw BinAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use a custom URLSession configuration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "omnibin-ios/1.0"
        ]
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw BinAPIError.httpError(httpResponse.statusCode, message: errorMessage)
        }
        
        let binResponse = try JSONDecoder().decode(BinResponse.self, from: data)
        return binResponse.items
    }
    
    // MARK: - Add Text Item
    func addTextItem(content: String, accessToken: String) async throws -> BinItem {
        do {
            return try await performAddTextItem(content: content, accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await refreshTokenIfNeeded()
            return try await performAddTextItem(content: content, accessToken: refreshedToken)
        }
    }
    
    private func performAddTextItem(content: String, accessToken: String) async throws -> BinItem {
        guard let url = URL(string: baseURL + binEndpoint) else {
            throw BinAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Unknown error"
            throw BinAPIError.httpError(httpResponse.statusCode, message: errorMessage)
        }
        
        return try JSONDecoder().decode(BinItem.self, from: data)
    }
    
    // MARK: - Delete Item
    func deleteItem(itemId: String, accessToken: String) async throws {
        do {
            try await performDeleteItem(itemId: itemId, accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await refreshTokenIfNeeded()
            try await performDeleteItem(itemId: itemId, accessToken: refreshedToken)
        }
    }
    
    private func performDeleteItem(itemId: String, accessToken: String) async throws {
        guard let url = URL(string: baseURL + binEndpoint + "/" + itemId) else {
            throw BinAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BinAPIError.httpError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Get File Download URL
    func getFileDownloadURL(itemId: String, accessToken: String) async throws -> String {
        do {
            return try await performGetFileDownloadURL(itemId: itemId, accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await refreshTokenIfNeeded()
            return try await performGetFileDownloadURL(itemId: itemId, accessToken: refreshedToken)
        }
    }
    
    private func performGetFileDownloadURL(itemId: String, accessToken: String) async throws -> String {
        guard let url = URL(string: baseURL + binEndpoint + "/" + itemId) else {
            throw BinAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinAPIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BinAPIError.httpError(httpResponse.statusCode)
        }
        
        let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let downloadURL = responseData?["url"] as? String else {
            throw BinAPIError.invalidResponse
        }
        
        return downloadURL
    }
}

// MARK: - Error Types
enum BinAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, message: String? = nil)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return message ?? "HTTP error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
