import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

extension BinView {
    func pasteFromClipboard() {
        guard accessToken != nil else {
            errorMessage = "No access token available"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let pasteboard = UIPasteboard.general
                // Prefer raw file URLs
                if let items = pasteboard.items as [[String: Any]]?, let fileURLString = items.compactMap({ $0["public.file-url"] as? String }).first, let url = URL(string: fileURLString), url.isFileURL {
                    do {
                        let data = try Data(contentsOf: url)
                        let originalName = url.lastPathComponent
                        let contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                        // Image dimensions if image
                        var imageWidth: Int? = nil
                        var imageHeight: Int? = nil
                        if let img = UIImage(data: data) {
                            imageWidth = Int(img.size.width)
                            imageHeight = Int(img.size.height)
                        }
                        let _ = try await BinAPI.shared.addFileItem(
                            fileData: data,
                            originalName: originalName,
                            contentType: contentType,
                            imageWidth: imageWidth,
                            imageHeight: imageHeight,
                            accessToken: accessToken!
                        )
                        await refreshBinItems()
                        isSubmitting = false
                        return
                    } catch {
                        // fall through to other handlers
                    }
                }

                // Next, prefer raw image data in known UTIs
                let knownImageTypes = [
                    "public.heic",
                    "public.heif",
                    "public.png",
                    "public.jpeg",
                    "public.tiff",
                    "com.compuserve.gif",
                ]
                for typeId in knownImageTypes {
                    if let data = pasteboard.data(forPasteboardType: typeId) {
                        let ut = UTType(typeId)
                        let contentType = ut?.preferredMIMEType ?? "application/octet-stream"
                        let ext = ut?.preferredFilenameExtension ?? "bin"
                        let baseName = getImageFileName() ?? "clipboard"
                        let originalName: String = baseName.contains(".") ? baseName : baseName + "." + ext
                        var imageWidth: Int? = nil
                        var imageHeight: Int? = nil
                        if let img = UIImage(data: data) {
                            imageWidth = Int(img.size.width)
                            imageHeight = Int(img.size.height)
                        }
                        let _ = try await BinAPI.shared.addFileItem(
                            fileData: data,
                            originalName: originalName,
                            contentType: contentType,
                            imageWidth: imageWidth,
                            imageHeight: imageHeight,
                            accessToken: accessToken!
                        )
                        await refreshBinItems()
                        isSubmitting = false
                        return
                    }
                }

                // Fallback: upload UIImage representation if available
                if let image = pasteboard.image {
                    await uploadImage(image)
                } else if let text = pasteboard.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await addTextItem(text: text)
                } else {
                    await setSubmittingError("No content found in clipboard")
                }
            }
        }
    }
    
    func uploadImage(_ image: UIImage) async {
        do {
            // Fallback: encode image once (PNG)
            guard let imageData = image.pngData() else {
                await setSubmittingError("Failed to process image")
                return
            }

            // Get image dimensions
            let size = image.size
            let imageWidth = Int(size.width)
            let imageHeight = Int(size.height)

            // Build filename preserving clipboard name if present; ensure it has an extension
            let baseName = getImageFileName() ?? "ios-image"
            let originalName: String = baseName.contains(".") ? baseName : baseName + ".png"

            // Upload the image
            let newItem = try await BinAPI.shared.addFileItem(
                fileData: imageData,
                originalName: originalName,
                contentType: "image/png",
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                accessToken: accessToken!
            )

            await insertNewItemAndFinishSubmitting(newItem)
        } catch {
            await setSubmittingError(error.localizedDescription)
        }
    }
    
    func getImageFileName() -> String? {
        // Try to get filename from clipboard items
        let pasteboard = UIPasteboard.general
        let items = pasteboard.items
        
        for item in items {
            // Check for various filename keys that might be present
            if let filename = item["public.filename"] as? String {
                return filename
            }
            if let filename = item["public.file-url"] as? String {
                return URL(string: filename)?.lastPathComponent
            }
            if let filename = item["public.url"] as? String {
                return URL(string: filename)?.lastPathComponent
            }
        }
        
        // Try to get from pasteboard's string representation
        if let string = pasteboard.string {
            // Look for common image filename patterns
            let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"]
            for ext in imageExtensions {
                if string.lowercased().contains(".\(ext)") {
                    // Extract filename from string if possible
                    let components = string.components(separatedBy: CharacterSet(charactersIn: " \n\t"))
                    for component in components {
                        if component.lowercased().hasSuffix(".\(ext)") {
                            return component
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func generateImageName(width: Int, height: Int) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "image-\(width)x\(height)-\(timestamp).jpg"
    }
    
    func addTextItem(text: String) async {
        do {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else {
                await setSubmittingError("No text content to add")
                return
            }
            
            if trimmedText.count > maxCharLimit {
                await setSubmittingError("Text content (\(trimmedText.count) characters) exceeds the \(maxCharLimit) character limit")
                return
            }
            
            let newItem = try await BinAPI.shared.addTextItem(content: trimmedText, accessToken: accessToken!)
            
            await insertNewItemAndFinishSubmitting(newItem)
        } catch {
            await setSubmittingError(error.localizedDescription)
        }
    }
    
    func addTextFromInput() {
        guard accessToken != nil else {
            errorMessage = "No access token available"
            return
        }
        
        let trimmedText = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorMessage = "No text content to add"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        textInput = "" // Clear the input
        
        Task {
            await addTextItem(text: trimmedText)
        }
    }
    
    func loadPhoto(_ photo: PhotosPickerItem) async {
        guard accessToken != nil else {
            errorMessage = "No access token available"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            // Load original data from the photo item
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                await setSubmittingError("Failed to load photo")
                return
            }
            // Determine content type and extension from data signature
            let detected = detectContentType(from: data)
            let contentType = detected.mime
            let ext = detected.ext
            var imageWidth: Int? = nil
            var imageHeight: Int? = nil
            if let img = UIImage(data: data) {
                imageWidth = Int(img.size.width)
                imageHeight = Int(img.size.height)
            }
            let originalName = "photo-\(Int(Date().timeIntervalSince1970)).\(ext)"
            let newItem = try await BinAPI.shared.addFileItem(
                fileData: data,
                originalName: originalName,
                contentType: contentType,
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                accessToken: accessToken!
            )
            await insertNewItemAndFinishSubmitting(newItem, resetSelection: true)
        } catch {
            await setSubmittingError(error.localizedDescription)
            await resetPhotoSelection()
        }
    }
    
    @MainActor
    func showSnackbar(message: String, type: MessageType) {
        snackbarMessage = message
        snackbarType = type
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            snackbarMessage = nil
            snackbarType = nil
        }
    }
    
    func loadBinItems() {
        guard let token = accessToken else {
            errorMessage = "No access token available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let items = try await BinAPI.shared.fetchBinItems(accessToken: token)
                await setLoadedItems(items)
            } catch {
                await setLoadingError(error.localizedDescription)
            }
        }
    }
    
    func refreshBinItems() async {
        guard let token = accessToken else {
            await setRefreshError("No access token available")
            return
        }
        
        do {
            let items = try await BinAPI.shared.fetchBinItems(accessToken: token)
            await setRefreshedItems(items)
        } catch {
            await setRefreshError(error.localizedDescription)
        }
    }
    
    func deleteItem(_ item: BinItem) {
        guard let token = accessToken else {
            errorMessage = "No access token available"
            return
        }
        
        Task {
            do {
                try await BinAPI.shared.deleteItem(itemId: item.id, accessToken: token)
                await removeItemById(item.id)
            } catch {
                await setRefreshError(error.localizedDescription)
            }
        }
    }
    
    func deleteItemById(_ itemId: String) {
        if let item = binItems.first(where: { $0.id == itemId }) {
            // Store the item for potential restoration
            deletedItems.append(item)
            // Remove from the main list
            binItems.removeAll { $0.id == itemId }
        }
    }
    
    func restoreItem(_ item: BinItem) {
        // Remove from deleted items and add back to main list
        deletedItems.removeAll { $0.id == item.id }
        binItems.append(item)
        // Sort to maintain order (you might want to insert at the original position)
        binItems.sort { $0.createdAt > $1.createdAt }
    }

    // MARK: - @MainActor UI helpers
    @MainActor
    func setSubmittingError(_ message: String) async {
        errorMessage = message
        isSubmitting = false
    }

    @MainActor
    func insertNewItemAndFinishSubmitting(_ newItem: BinItem, resetSelection: Bool = false) async {
        binItems.insert(newItem, at: 0)
        if binItems.count > binItemsLimit {
            binItems.removeLast()
        }
        isSubmitting = false
        if resetSelection {
            selectedPhoto = nil
        }
    }

    @MainActor
    func resetPhotoSelection() async {
        selectedPhoto = nil
    }

    @MainActor
    func setLoadedItems(_ items: [BinItem]) async {
        binItems = items
        isLoading = false
    }

    @MainActor
    func setLoadingError(_ message: String) async {
        errorMessage = message
        isLoading = false
    }

    @MainActor
    func setRefreshedItems(_ items: [BinItem]) async {
        binItems = items
        errorMessage = nil
    }

    @MainActor
    func setRefreshError(_ message: String) async {
        errorMessage = message
    }

    @MainActor
    func removeItemById(_ id: String) async {
        binItems.removeAll { $0.id == id }
    }
}


