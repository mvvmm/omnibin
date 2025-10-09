import Foundation
import UniformTypeIdentifiers

// MARK: - File Helpers
func createFileProvider(from tmpURL: URL, filename: String) -> NSItemProvider? {
    // Build desired filename and unique dest directory
    let raw = (filename as NSString).lastPathComponent
    let base = (raw as NSString).deletingPathExtension.isEmpty ? "file" : (raw as NSString).deletingPathExtension
    let ext  = (raw as NSString).pathExtension
    let type = UTType(filenameExtension: ext) ?? .data
    let ensuredExt = ext.isEmpty ? (type.preferredFilenameExtension ?? "") : ext
    let desired = ensuredExt.isEmpty ? base : "\(base).\(ensuredExt)"

    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    do {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(desired)
        // Move/rename the downloaded temp file to our desired url
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: tmpURL, to: url)

        // Explicit UTType + openInPlace improves name preservation
        let explicitType = UTType(filenameExtension: url.pathExtension) ?? .data
        let provider = NSItemProvider()
        provider.suggestedName = desired
        provider.registerFileRepresentation(
            forTypeIdentifier: explicitType.identifier,
            fileOptions: [.openInPlace],
            visibility: .all
        ) { completion in
            completion(url, true, nil)
            return nil
        }
        
        return provider
    } catch {
        return nil
    }
}
