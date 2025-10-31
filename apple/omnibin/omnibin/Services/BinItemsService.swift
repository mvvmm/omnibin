import Foundation

// MARK: - Bin Items API Service
class BinItemsService {
    static let shared = BinItemsService()
    
    private let networkClient = NetworkClient.shared
    private let authService = AuthenticationService.shared
    private let networkConfig = NetworkConfiguration.shared
    
    private init() {}
    
    // MARK: - Fetch Bin Items
    func fetchBinItems(accessToken: String, bypassCache: Bool = false) async throws -> [BinItem] {
        do {
            return try await performFetchBinItems(accessToken: accessToken, bypassCache: bypassCache)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await authService.refreshTokenIfNeeded()
            return try await performFetchBinItems(accessToken: refreshedToken, bypassCache: bypassCache)
        }
    }
    
    private func performFetchBinItems(accessToken: String, bypassCache: Bool = false) async throws -> [BinItem] {
        guard authService.validateToken(accessToken) else {
            throw BinAPIError.httpError(401, message: "No access token provided")
        }
        
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let cachePolicy: URLRequest.CachePolicy = bypassCache ? .reloadIgnoringLocalAndRemoteCacheData : .useProtocolCachePolicy
        let (data, _) = try await networkClient.makeRequest(
            endpoint: networkConfig.binEndpoint,
            method: .GET,
            headers: headers,
            cachePolicy: cachePolicy
        )
        
        let binResponse = try JSONDecoder().decode(BinResponse.self, from: data)
        return binResponse.items
    }
    
    // MARK: - Add Text Item
    func addTextItem(content: String, accessToken: String) async throws -> BinItem {
        do {
            return try await performAddTextItem(content: content, accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await authService.refreshTokenIfNeeded()
            return try await performAddTextItem(content: content, accessToken: refreshedToken)
        }
    }
    
    private func performAddTextItem(content: String, accessToken: String) async throws -> BinItem {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let requestBody = ["content": content]
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await networkClient.makeRequest(
            endpoint: networkConfig.binEndpoint,
            method: .POST,
            headers: headers,
            body: bodyData
        )
        
        return try JSONDecoder().decode(BinItem.self, from: data)
    }
    
    // MARK: - Delete Item
    func deleteItem(itemId: String, accessToken: String) async throws {
        do {
            try await performDeleteItem(itemId: itemId, accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await authService.refreshTokenIfNeeded()
            try await performDeleteItem(itemId: itemId, accessToken: refreshedToken)
        }
    }
    
    private func performDeleteItem(itemId: String, accessToken: String) async throws {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let _ = try await networkClient.makeRequest(
            endpoint: "\(networkConfig.binEndpoint)/\(itemId)",
            method: .DELETE,
            headers: headers
        )
    }
    
    // MARK: - Get File Download URL
    func getFileDownloadURL(itemId: String, accessToken: String) async throws -> String {
        do {
            return try await performGetFileDownloadURL(itemId: itemId, accessToken: accessToken)
        } catch BinAPIError.httpError(401, _) {
            // Token might be expired, try to refresh
            let refreshedToken = try await authService.refreshTokenIfNeeded()
            return try await performGetFileDownloadURL(itemId: itemId, accessToken: refreshedToken)
        }
    }
    
    private func performGetFileDownloadURL(itemId: String, accessToken: String) async throws -> String {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let (data, _) = try await networkClient.makeRequest(
            endpoint: "\(networkConfig.binEndpoint)/\(itemId)",
            method: .GET,
            headers: headers
        )
        
        let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let downloadURL = responseData?["url"] as? String else {
            throw BinAPIError.invalidResponse
        }
        
        return downloadURL
    }
}
