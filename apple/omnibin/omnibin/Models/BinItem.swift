import Foundation

// MARK: - Bin Item Model
struct BinItem: Codable, Identifiable {
    let id: String
    let userId: String
    let kind: String // "TEXT" or "FILE"
    let textItem: TextItem?
    let fileItem: FileItem?
    let createdAt: String
    let updatedAt: String
}
