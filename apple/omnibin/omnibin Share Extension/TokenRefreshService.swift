import Foundation

struct TokenRefreshService {
    private static let auth0Domain = "auth.omnib.in"
    private static let clientId = "zVUb4oc3Wfi3tE6w7RYP6CtPt4QU0wbw"

    struct TokenResponse: Codable {
        let accessToken: String
        let idToken: String?
        let refreshToken: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case idToken = "id_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }

    /// Refreshes the access token using a refresh token
    /// - Parameter refreshToken: The refresh token to use
    /// - Returns: A new access token
    /// - Throws: Error if the refresh fails
    static func refreshAccessToken(using refreshToken: String) async throws -> TokenResponse {
        guard let url = URL(string: "https://\(auth0Domain)/oauth/token") else {
            throw NSError(
                domain: "TokenRefreshService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid token endpoint URL"]
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": clientId,
            "refresh_token": refreshToken
        ]

        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "TokenRefreshService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response"]
            )
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "TokenRefreshService",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Token refresh failed: \(errorMessage)"]
            )
        }

        let decoder = JSONDecoder()
        let tokenResponse = try decoder.decode(TokenResponse.self, from: data)

        return tokenResponse
    }
}
