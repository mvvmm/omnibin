import Foundation

// MARK: - BinAPI
// This file now serves as the main entry point for all BinAPI-related functionality
// Individual components have been extracted into separate files for better organization

class BinAPI: ObservableObject {
    static let shared = BinAPI()

    // Service dependencies
    private let binItemsService = BinItemsService.shared
    private let fileUploadService = FileUploadService.shared
    private let openGraphService = OpenGraphService.shared

    private init() {}

    // MARK: - Public API Methods (Facade Pattern)

    func fetchBinItems(accessToken: String) async throws -> [BinItem] {
        return try await binItemsService.fetchBinItems(accessToken: accessToken)
    }

    func addTextItem(content: String, accessToken: String) async throws -> BinItem {
        return try await binItemsService.addTextItem(content: content, accessToken: accessToken)
    }

    func deleteItem(itemId: String, accessToken: String) async throws {
        try await binItemsService.deleteItem(itemId: itemId, accessToken: accessToken)
    }

    func getFileDownloadURL(itemId: String, accessToken: String) async throws -> String {
        return try await binItemsService.getFileDownloadURL(itemId: itemId, accessToken: accessToken)
    }

    func addFileItem(
        fileData: Data,
        originalName: String,
        contentType: String,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        accessToken: String
    ) async throws -> BinItem {
        return try await fileUploadService.addFileItem(
            fileData: fileData,
            originalName: originalName,
            contentType: contentType,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            accessToken: accessToken
        )
    }

    func fetchOpenGraph(url: String, accessToken: String) async throws -> OGData? {
        return try await openGraphService.fetchOpenGraph(url: url, accessToken: accessToken)
    }
}

// MARK: - Re-export for Backward Compatibility
// The actual implementations are now in separate files:
// - Models/BinAPIError.swift
// - Models/OGData.swift
// - Services/NetworkConfiguration.swift
// - Services/NetworkClient.swift
// - Services/AuthenticationService.swift
// - Services/BinItemsService.swift
// - Services/FileUploadService.swift
// - Services/OpenGraphService.swift
