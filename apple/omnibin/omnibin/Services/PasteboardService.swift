import UIKit
import UniformTypeIdentifiers

/// Service for handling pasteboard operations and file loading
class PasteboardService {
    static let shared = PasteboardService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Load content from pasteboard and return as either text, image, or file data
    func loadFromPasteboard() async throws -> PasteboardContent {
        let pasteboard = UIPasteboard.general
        
        // First check if there are item providers (better for file handling)
        let itemProviders = pasteboard.itemProviders
        if !itemProviders.isEmpty {
            let provider = itemProviders[0]
            
            // Check for image type first (most common from Messages)
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                let image = try await loadImage(from: provider)
                return .image(image)
            }
            
            // Check for common file types
            if let fileContent = try await loadFile(from: provider) {
                return .file(fileContent)
            }
        }
        
        // Check if pasteboard contains a file URL (e.g., from Messages)
        if let string = pasteboard.string,
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           string.hasPrefix("file://"),
           let fileURL = URL(string: string),
           fileURL.isFileURL {
            let fileContent = try await loadFile(from: fileURL)
            return .file(fileContent)
        }
        
        // Check for regular text
        if let string = pasteboard.string, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .text(string)
        }
        
        // Check for image directly on pasteboard
        if let image = pasteboard.image {
            return .image(image)
        }
        
        throw PasteboardError.noContent
    }
    
    // MARK: - Private Methods
    
    private func loadImage(from provider: NSItemProvider) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { object, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let image = object as? UIImage {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: PasteboardError.invalidImage)
                }
            }
        }
    }
    
    private func loadFile(from provider: NSItemProvider) async throws -> FileContent? {
        // Check common file types that can be loaded directly
        let commonTypes: [UTType] = [
            .pdf, .png, .jpeg, .gif, .heic, .heif,
            .mpeg4Movie, .quickTimeMovie,
            .zip
        ]
        
        for utType in commonTypes {
            if provider.hasItemConformingToTypeIdentifier(utType.identifier) {
                let contentType = utType.preferredMIMEType ?? "application/octet-stream"
                let (data, filename) = try await loadFileData(from: provider, typeIdentifier: utType.identifier)
                return FileContent(data: data, filename: filename, contentType: contentType)
            }
        }
        
        // Fall back to generic file URL if no specific type matched
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            let fileURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let url = item as? URL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: PasteboardError.invalidFileURL)
                    }
                }
            }
            return try await loadFile(from: fileURL)
        }
        
        return nil
    }
    
    private func loadFileData(from provider: NSItemProvider, typeIdentifier: String) async throws -> (Data, String) {
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let url = url else {
                    continuation.resume(throwing: PasteboardError.noFileURL)
                    return
                }
                
                do {
                    // Read the file data immediately while we have access
                    let data = try Data(contentsOf: url)
                    let filename = url.lastPathComponent
                    continuation.resume(returning: (data, filename))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func loadFile(from fileURL: URL) async throws -> FileContent {
        // Start accessing security-scoped resource
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Try to access the file
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw PasteboardError.fileNotFound
        }
        
        // Load file data
        let fileData = try Data(contentsOf: fileURL)
        let filename = fileURL.lastPathComponent
        
        // Detect content type from file extension and data
        let contentType = detectContentType(from: fileData, url: fileURL)
        
        return FileContent(data: fileData, filename: filename, contentType: contentType)
    }
    
}

// MARK: - Types

enum PasteboardContent {
    case text(String)
    case image(UIImage)
    case file(FileContent)
}

struct FileContent {
    let data: Data
    let filename: String
    let contentType: String
}

enum PasteboardError: LocalizedError {
    case noContent
    case invalidImage
    case invalidFileURL
    case noFileURL
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .noContent:
            return "No text or image found in clipboard"
        case .invalidImage:
            return "Invalid image data"
        case .invalidFileURL:
            return "Invalid file URL"
        case .noFileURL:
            return "No file URL provided"
        case .fileNotFound:
            return "File not found"
        }
    }
}

