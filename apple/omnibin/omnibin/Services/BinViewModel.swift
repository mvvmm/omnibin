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
    @Published var snackbarMessage: String?
    @Published var snackbarType: MessageType?
    @Published var showTextInputDialog = false
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
                    self.errorMessage = "Failed to load items: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshBinItems() async {
        guard let token = accessToken else { return }
        
        do {
            let items = try await BinAPI.shared.fetchBinItems(accessToken: token)
            await MainActor.run {
                self.binItems = items
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to refresh items: \(error.localizedDescription)"
            }
        }
    }
    
    func pasteFromClipboard() {
        guard let token = accessToken else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let pasteboard = UIPasteboard.general
                
                if let string = pasteboard.string, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let item = try await BinAPI.shared.addTextItem(content: string, accessToken: token)
                    await MainActor.run {
                        self.binItems.insert(item, at: 0)
                        self.isSubmitting = false
                        self.showSnackbar(message: "Text pasted successfully", type: .success)
                    }
                } else if let image = pasteboard.image {
                    await addImageToBin(image: image, token: token)
                } else {
                    await MainActor.run {
                        self.errorMessage = "No text or image found in clipboard"
                        self.isSubmitting = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to paste: \(error.localizedDescription)"
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
                    self.showSnackbar(message: "Text added successfully", type: .success)
                }
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
    
    func showSnackbar(message: String, type: MessageType) {
        snackbarMessage = message
        snackbarType = type
        
        // Auto-hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                self.snackbarMessage = nil
                self.snackbarType = nil
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func addImageToBin(image: UIImage, token: String) async {
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
                self.showSnackbar(message: "Image added successfully", type: .success)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to add image: \(error.localizedDescription)"
                self.isSubmitting = false
            }
        }
    }
}
