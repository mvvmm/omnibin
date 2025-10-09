import Foundation

// MARK: - Open Graph Service
class OpenGraphService {
    static let shared = OpenGraphService()
    
    private let networkClient = NetworkClient.shared
    private let authService = AuthenticationService.shared
    private let networkConfig = NetworkConfiguration.shared
    
    private init() {}
    
    // MARK: - Fetch Open Graph Data
    func fetchOpenGraph(url: String, accessToken: String) async throws -> OGData? {
        let headers = ["Authorization": "Bearer \(accessToken)"]
        let body: [String: String] = ["url": url]
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await networkClient.makeRequest(
            endpoint: networkConfig.ogEndpoint,
            method: .POST,
            headers: headers,
            body: bodyData
        )
        
        // Return nil for non-200 status codes (graceful degradation)
        guard (200...299).contains(response.statusCode) else {
            return nil
        }
        
        let decoded = try JSONDecoder().decode(OGResponse.self, from: data)
        return decoded.og
    }
}
