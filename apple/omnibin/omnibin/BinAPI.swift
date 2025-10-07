import Foundation
import Auth0

class BinAPI: ObservableObject {
    static let shared = BinAPI()
    
    // Base URL for the backend. Defaults to production, but can be overridden for dev/testing.
    private var baseURL: String {
        // 1) Runtime override via UserDefaults (useful for QA toggles)
        if let override = UserDefaults.standard.string(forKey: "OMNIBIN_BASE_URL"), !override.isEmpty {
            return override
        }
        // 2) Info.plist key (set per build configuration)
        if let fromPlist = Bundle.main.object(forInfoDictionaryKey: "OMNIBIN_BASE_URL") as? String, !fromPlist.isEmpty {
            return fromPlist
        }
        // 3) Debug env var for simulators
        #if DEBUG
        if let fromEnv = ProcessInfo.processInfo.environment["OMNIBIN_BASE_URL"], !fromEnv.isEmpty {
            return fromEnv
        }
        #endif
        // 4) Fallback to production
        return "https://www.omnib.in"
    }
    private let binEndpoint = "/api/bin"
    private let ogEndpoint  = "/api/og"
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

    // MARK: - Open Graph (URL Preview)
    struct OGData: Codable {
        let url: String?
        let title: String?
        let description: String?
        let image: String?
        let icon: String?
        let siteName: String?
    }

    private struct OGResponse: Codable { let og: OGData? }

    func fetchOpenGraph(url: String, accessToken: String) async throws -> OGData? {
        guard let requestURL = URL(string: baseURL + ogEndpoint) else {
            throw BinAPIError.invalidURL
        }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["url": url]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw BinAPIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { return nil }
        let decoded = try JSONDecoder().decode(OGResponse.self, from: data)
        return decoded.og
    }
    
    // MARK: - Add File Item
    func addFileItem(fileData: Data, originalName: String, contentType: String, imageWidth: Int? = nil, imageHeight: Int? = nil, accessToken: String) async throws -> BinItem {
        do {
            return try await performAddFileItem(fileData: fileData, originalName: originalName, contentType: contentType, imageWidth: imageWidth, imageHeight: imageHeight, accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await refreshTokenIfNeeded()
            return try await performAddFileItem(fileData: fileData, originalName: originalName, contentType: contentType, imageWidth: imageWidth, imageHeight: imageHeight, accessToken: refreshedToken)
        }
    }
    
    private func performAddFileItem(fileData: Data, originalName: String, contentType: String, imageWidth: Int?, imageHeight: Int?, accessToken: String) async throws -> BinItem {
        guard let url = URL(string: baseURL + binEndpoint) else {
            throw BinAPIError.invalidURL
        }
        
        // Step 1: Request upload URL from server
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let fileMetadata: [String: Any] = [
            "originalName": originalName,
            "contentType": contentType,
            "size": fileData.count,
            "imageWidth": imageWidth as Any,
            "imageHeight": imageHeight as Any
        ]
        
        let requestBody = ["file": fileMetadata]
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
        
        let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let uploadURLString = responseData?["uploadUrl"] as? String,
              let uploadURL = URL(string: uploadURLString) else {
            throw BinAPIError.invalidResponse
        }
        
        // Step 2: Upload file to S3
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "PUT"
        uploadRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        uploadRequest.httpBody = fileData
        
        let (_, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)
        
        guard let uploadHttpResponse = uploadResponse as? HTTPURLResponse else {
            throw BinAPIError.invalidResponse
        }
        
        guard (200...299).contains(uploadHttpResponse.statusCode) else {
            throw BinAPIError.httpError(uploadHttpResponse.statusCode, message: "Failed to upload file to storage")
        }
        
        // Step 3: Parse and return the BinItem
        guard let itemData = responseData?["item"] as? [String: Any] else {
            throw BinAPIError.invalidResponse
        }
        
        let itemJSON = try JSONSerialization.data(withJSONObject: itemData)
        return try JSONDecoder().decode(BinItem.self, from: itemJSON)
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
