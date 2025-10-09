import SwiftUI
import UniformTypeIdentifiers

struct DataDoc: FileDocument {
    static var readableContentTypes: [UTType] = [.data]

    static var writableContentTypes: [UTType] = [
        .data, .pdf, .png, .jpeg, .plainText, .json, .zip
    ]

    var data: Data
    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
