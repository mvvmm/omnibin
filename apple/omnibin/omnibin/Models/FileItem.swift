import Foundation

// MARK: - File Item Model
struct FileItem: Codable {
    let id: String
    let provider: String
    let bucket: String
    let key: String
    let originalName: String
    let contentType: String
    let size: String // BigInt from Prisma is serialized as String
    let checksum: String?
    let preview: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let expiresAt: String?
    let createdAt: String
    let updatedAt: String
}
