import Foundation

// MARK: - API Error Types
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
