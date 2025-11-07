import Foundation

// MARK: - Text Item Model
struct TextItem: Codable {
    let id: String
    let content: String
    
    // Open Graph data
    let ogDataFetched: Bool?
    let ogTitle: String?
    let ogDescription: String?
    let ogImage: String?
    let ogImageWidth: Int?
    let ogImageHeight: Int?
    let ogIcon: String?
    let ogSiteName: String?
    
    let createdAt: String
    let updatedAt: String
}
