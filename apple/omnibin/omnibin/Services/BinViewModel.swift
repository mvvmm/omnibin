import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Bin View Model
@MainActor
class BinViewModel: ObservableObject {
    @Published var binItems: [BinItem] = []
    @Published var deletedItems: [BinItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSubmitting = false
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var showTextInputDialog = false
    @Published var showFileImporter = false
    @Published var textInput = ""
    
    let accessToken: String?
    let maxCharLimit = 10000
    let binItemsLimit = 10
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    // MARK: - Public Methods
    
    func loadBinItems() {
        guard let token = accessToken else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let items = try await BinAPI.shared.fetchBinItems(accessToken: token)
                await MainActor.run {
                    self.binItems = items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Create a user-friendly error message
                    let friendlyMessage: String
                    if let apiError = error as? BinAPIError {
                        switch apiError {
                        case .httpError(_, let message):
                            if let msg = message, (msg.contains("<html") || msg.contains("<!DOCTYPE")) {
                                friendlyMessage = "Network request blocked. Please try again later."
                            } else {
                                friendlyMessage = message ?? "Network error occurred"
                            }
                        default:
                            friendlyMessage = "Network error occurred"
                        }
                    } else {
                        let errorDesc = error.localizedDescription
                        if errorDesc.contains("<html") || errorDesc.contains("<!DOCTYPE") || errorDesc.count > 500 {
                            friendlyMessage = "Network request blocked. Please try again later."
                        } else {
                            friendlyMessage = errorDesc
                        }
                    }
                    self.errorMessage = "Failed to load items: \(friendlyMessage)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshBinItems() async {
        guard let token = accessToken else { return }
        
        errorMessage = nil
        
        // Use Task.detached to run the network request outside of SwiftUI's refreshable lifecycle
        // This prevents the task from being cancelled when the refresh gesture completes
        // Also bypass cache to ensure we get fresh data
        do {
            let items = try await Task.detached(priority: .userInitiated) {
                try await BinAPI.shared.fetchBinItems(accessToken: token, bypassCache: true)
            }.value
            
            await MainActor.run {
                self.binItems = items
            }
        } catch {
            // Silently ignore cancellation errors - these occur when the user
            // releases the refresh gesture before completion, which is normal behavior
            if error is CancellationError {
                return
            }
            
            // Also check for URLSession cancellation errors
            if let urlError = error as? URLError, urlError.code == .cancelled {
                return
            }
            
            await MainActor.run {
                // Create a user-friendly error message
                let friendlyMessage: String
                if let apiError = error as? BinAPIError {
                    switch apiError {
                    case .httpError(_, let message):
                        // If message contains HTML tags, provide a generic message
                        if let msg = message, (msg.contains("<html") || msg.contains("<!DOCTYPE")) {
                            friendlyMessage = "Network request blocked. Please try again later."
                        } else {
                            friendlyMessage = message ?? "Network error occurred"
                        }
                    default:
                        friendlyMessage = "Network error occurred"
                    }
                } else {
                    // For other errors, check if localizedDescription contains HTML
                    let errorDesc = error.localizedDescription
                    if errorDesc.contains("<html") || errorDesc.contains("<!DOCTYPE") || errorDesc.count > 500 {
                        friendlyMessage = "Network request blocked. Please try again later."
                    } else {
                        friendlyMessage = errorDesc
                    }
                }
                self.errorMessage = "Failed to refresh items: \(friendlyMessage)"
            }
        }
    }
    
    func pasteFromClipboard(onSuccess: (() -> Void)? = nil) {
        guard let token = accessToken else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let content = try await PasteboardService.shared.loadFromPasteboard()
                
                switch content {
                case .text(let text):
                    let item = try await BinAPI.shared.addTextItem(content: text, accessToken: token)
                    await MainActor.run {
                        self.binItems.insert(item, at: 0)
                        self.isSubmitting = false
                        onSuccess?()
                    }
                    await refreshBinItems()
                    
                case .image(let image):
                    await addImageToBin(image: image, token: token, onSuccess: onSuccess)
                    
                case .file(let fileContent):
                    // Check if file is actually an image
                    if let image = UIImage(data: fileContent.data) {
                        let item = try await BinAPI.shared.addFileItem(
                            fileData: fileContent.data,
                            originalName: fileContent.filename,
                            contentType: fileContent.contentType,
                            imageWidth: Int(image.size.width),
                            imageHeight: Int(image.size.height),
                            accessToken: token
                        )
                        await MainActor.run {
                            self.binItems.insert(item, at: 0)
                            self.isSubmitting = false
                            onSuccess?()
                        }
                    } else {
                        let item = try await BinAPI.shared.addFileItem(
                            fileData: fileContent.data,
                            originalName: fileContent.filename,
                            contentType: fileContent.contentType,
                            accessToken: token
                        )
                        await MainActor.run {
                            self.binItems.insert(item, at: 0)
                            self.isSubmitting = false
                            onSuccess?()
                        }
                    }
                    await refreshBinItems()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSubmitting = false
                }
            }
        }
    }
    
    func addTextFromInput() {
        guard let token = accessToken else { return }
        guard !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let item = try await BinAPI.shared.addTextItem(content: textInput, accessToken: token)
                await MainActor.run {
                    self.binItems.insert(item, at: 0)
                    self.textInput = ""
                    self.showTextInputDialog = false
                    self.isSubmitting = false
                }
                // Refresh items to get accurate state after adding (in case oldest was deleted)
                await refreshBinItems()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add text: \(error.localizedDescription)"
                    self.isSubmitting = false
                }
            }
        }
    }
    
    func loadPhoto(_ photo: PhotosPickerItem) async {
        guard let token = accessToken else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    self.errorMessage = "Failed to load photo data"
                    self.isSubmitting = false
                }
                return
            }
            
            guard let image = UIImage(data: data) else {
                await MainActor.run {
                    self.errorMessage = "Invalid image data"
                    self.isSubmitting = false
                }
                return
            }
            
            await addImageToBin(image: image, token: token)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load photo: \(error.localizedDescription)"
                self.isSubmitting = false
            }
        }
    }
    
    func deleteItemById(_ itemId: String) {
        // Optimistic delete - remove from UI immediately
        if let index = binItems.firstIndex(where: { $0.id == itemId }) {
            let deletedItem = binItems.remove(at: index)
            deletedItems.append(deletedItem)
        }
    }
    
    func restoreItem(_ item: BinItem) {
        // Restore item to UI
        binItems.insert(item, at: 0)
        deletedItems.removeAll { $0.id == item.id }
    }
    
    func loadFile(from url: URL) async {
        guard let token = accessToken else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                await MainActor.run {
                    self.errorMessage = "Failed to access file"
                    self.isSubmitting = false
                }
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let fileData = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            
            // Detect content type
            let contentType = detectContentType(from: fileData, url: url)
            
            // Check if it's an image to get dimensions
            if let image = UIImage(data: fileData) {
                let item = try await BinAPI.shared.addFileItem(
                    fileData: fileData,
                    originalName: filename,
                    contentType: contentType,
                    imageWidth: Int(image.size.width),
                    imageHeight: Int(image.size.height),
                    accessToken: token
                )
                await MainActor.run {
                    self.binItems.insert(item, at: 0)
                    self.isSubmitting = false
                }
            } else {
                let item = try await BinAPI.shared.addFileItem(
                    fileData: fileData,
                    originalName: filename,
                    contentType: contentType,
                    accessToken: token
                )
                await MainActor.run {
                    self.binItems.insert(item, at: 0)
                    self.isSubmitting = false
                }
            }
            
            // Refresh items to get accurate state after adding
            await refreshBinItems()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load file: \(error.localizedDescription)"
                self.isSubmitting = false
            }
        }
    }
    
    
    // MARK: - Private Methods
    
    private func addImageToBin(image: UIImage, token: String, onSuccess: (() -> Void)? = nil) async {
        do {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                await MainActor.run {
                    self.errorMessage = "Failed to process image"
                    self.isSubmitting = false
                }
                return
            }
            
            let item = try await BinAPI.shared.addFileItem(
                fileData: imageData,
                originalName: "image.jpg",
                contentType: "image/jpeg",
                imageWidth: Int(image.size.width),
                imageHeight: Int(image.size.height),
                accessToken: token
            )
            
            await MainActor.run {
                self.binItems.insert(item, at: 0)
                self.isSubmitting = false
                onSuccess?()
            }
            // Refresh items to get accurate state after adding (in case oldest was deleted)
            await refreshBinItems()
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add image: \(error.localizedDescription)"
                self.isSubmitting = false
            }
        }
    }
}
