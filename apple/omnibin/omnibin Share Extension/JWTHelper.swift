import Foundation

struct JWTHelper {
    /// Decodes a JWT token and checks if it's expired
    /// - Parameter token: The JWT token string
    /// - Returns: true if the token is expired, false if it's still valid
    static func isTokenExpired(_ token: String) -> Bool {
        guard let payload = decodePayload(from: token) else {
            // If we can't decode, assume expired
            return true
        }

        guard let exp = payload["exp"] as? TimeInterval else {
            // If no expiration, assume expired
            return true
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        let now = Date()

        // Add a 60-second buffer to refresh before actual expiration
        let bufferSeconds: TimeInterval = 60
        return now.addingTimeInterval(bufferSeconds) >= expirationDate
    }

    /// Decodes the payload (claims) from a JWT token
    /// - Parameter token: The JWT token string
    /// - Returns: Dictionary containing the JWT payload, or nil if decoding fails
    private static func decodePayload(from token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count == 3 else {
            return nil
        }

        // JWT payload is the second segment
        let payloadSegment = segments[1]

        // Convert from base64url to base64
        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if needed
        let paddingLength = (4 - base64.count % 4) % 4
        base64 += String(repeating: "=", count: paddingLength)

        guard let data = Data(base64Encoded: base64) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }

        return json
    }
}
