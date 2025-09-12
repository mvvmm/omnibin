import Foundation

struct TextItem: Codable {
    let id: String
    let content: String
    let createdAt: String
    let updatedAt: String
}

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

struct BinItem: Codable, Identifiable {
    let id: String
    let userId: String
    let kind: String // "TEXT" or "FILE"
    let textItem: TextItem?
    let fileItem: FileItem?
    let createdAt: String
    let updatedAt: String
    
    var isText: Bool {
        kind == "TEXT"
    }
    
    var isFile: Bool {
        kind == "FILE"
    }
}

struct BinResponse: Codable {
    let items: [BinItem]
}

// MARK: - File Size Formatting
extension FileItem {
    func formattedSize() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        let sizeInt = Int64(size) ?? 0
        return formatter.string(fromByteCount: sizeInt)
    }
}

// MARK: - Date Formatting
extension BinItem {
    func formattedCreatedAt() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
        let date = ISO8601DateFormatter().date(from: createdAt) ?? Date()
        return formatter.string(from: date)
    }
}
