import Foundation

// MARK: - Open Graph Data Model
struct OGData: Codable {
    let url: String?
    let title: String?
    let description: String?
    let image: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let icon: String?
    let siteName: String?
}

// MARK: - Open Graph Response Wrapper
struct OGResponse: Codable {
    let og: OGData?
}
