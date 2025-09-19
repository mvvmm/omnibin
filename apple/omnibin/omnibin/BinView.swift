import SwiftUI
import UIKit
import PhotosUI

struct BinView: View {
    let accessToken: String?
    let onLogout: () -> Void
    
    @State private var binItems: [BinItem] = []
    @State private var deletedItems: [BinItem] = [] // Store deleted items for potential restoration
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var snackbarMessage: String?
    @State private var snackbarType: MessageType?
    @State private var showTextInputDialog = false
    @State private var textInput = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    private let maxCharLimit = 10000
    private let binItemsLimit = 10
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Your Bin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            onLogout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.Button.accentPrimary)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                .padding(.horizontal, min(24, geometry.size.width * 0.05))
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Add new item form
                        VStack(spacing: 12) {
                            // Paste from Clipboard button (full width)
                            Button(action: pasteFromClipboard) {
                                HStack(spacing: 12) {
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    
                                    Text(isSubmitting ? "Pasting..." : "Paste from Clipboard")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    AppColors.Button.accentPrimary,
                                                    AppColors.Button.accentSecondary
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: AppColors.Button.accentPrimary.opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                                .scaleEffect(isSubmitting ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: isSubmitting)
                            }
                            .disabled(isSubmitting)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            
                            // Text and Photos buttons row
                            HStack(spacing: 12) {
                                // Add Text button
                                Button(action: { showTextInputDialog = true }) {
                                    Image(systemName: "textformat")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                                                )
                                                .shadow(
                                                    color: AppColors.cardShadow(isDarkMode: isDarkMode),
                                                    radius: 4,
                                                    x: 0,
                                                    y: 2
                                                )
                                        )
                                }
                                .disabled(isSubmitting)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                
                                // Upload from Photos button
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                                                )
                                                .shadow(
                                                    color: AppColors.cardShadow(isDarkMode: isDarkMode),
                                                    radius: 4,
                                                    x: 0,
                                                    y: 2
                                                )
                                        )
                                }
                                .disabled(isSubmitting)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                            }
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Items: \(binItems.count) / \(binItemsLimit)")
                                    .font(.caption)
                                    .foregroundColor(binItems.count >= binItemsLimit ? .red : AppColors.mutedText(isDarkMode: isDarkMode))
                                
                                if binItems.count >= binItemsLimit {
                                    Text("Oldest item will be deleted on next add.")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Items list
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.Button.accentPrimary))
                                
                                Text("Loading your bin...")
                                    .font(.headline)
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                            }
                            .padding(.top, 60)
                        } else if binItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                                
                                Text("No items yet")
                                    .font(.headline)
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                                
                                Text("Paste text or files to get started")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                            }
                            .padding(.top, 60)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(binItems, id: \.id) { item in
                                    BinItemRow(item: item, accessToken: accessToken, onDelete: {
                                        deleteItemById(item.id)
                                    }, onRestore: {
                                        restoreItem(item)
                                    }, onShowMessage: { message, type in
                                        showSnackbar(message: message, type: type)
                                    })
                                    .id(item.id)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .padding(.horizontal, min(24, geometry.size.width * 0.05))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .refreshable {
            await refreshBinItems()
        }
        .onAppear {
            loadBinItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
            // Refresh bin items when app becomes active
            Task {
                await refreshBinItems()
            }
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let newPhoto = newPhoto {
                Task {
                    await loadPhoto(newPhoto)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let snackbarMessage = snackbarMessage, let snackbarType = snackbarType {
                SnackbarView(message: snackbarMessage, type: snackbarType) {
                    self.snackbarMessage = nil
                    self.snackbarType = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: snackbarMessage)
            }
        }
        .alert("Add Text Item", isPresented: $showTextInputDialog) {
            TextField("Enter text...", text: $textInput, axis: .vertical)
                .lineLimit(5...10)
            Button("Cancel", role: .cancel) {
                textInput = ""
            }
            Button("Add") {
                addTextFromInput()
            }
            .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter the text you want to add to your bin.")
        }
    }
    
    private func pasteFromClipboard() {
        guard accessToken != nil else {
            errorMessage = "No access token available"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                // Check for image first
                if let image = UIPasteboard.general.image {
                    await uploadImage(image)
                }
                // Check for text
                else if let text = UIPasteboard.general.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await addTextItem(text: text)
                }
                else {
                    await setSubmittingError("No content found in clipboard")
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) async {
        do {
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                await setSubmittingError("Failed to process image")
                return
            }
            
            // Get image dimensions
            let size = image.size
            let imageWidth = Int(size.width)
            let imageHeight = Int(size.height)
            
            // Try to get original filename from clipboard metadata
            let originalName = getImageFileName() ?? "ios-image.jpg"
            
            // Upload the image
            let newItem = try await BinAPI.shared.addFileItem(
                fileData: imageData,
                originalName: originalName,
                contentType: "image/jpeg",
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                accessToken: accessToken!
            )
            
            await insertNewItemAndFinishSubmitting(newItem)
        } catch {
            await setSubmittingError(error.localizedDescription)
        }
    }
    
    private func getImageFileName() -> String? {
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
    
    private func generateImageName(width: Int, height: Int) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "image-\(width)x\(height)-\(timestamp).jpg"
    }
    
    private func addTextItem(text: String) async {
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
    
    private func addTextFromInput() {
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
    
    private func loadPhoto(_ photo: PhotosPickerItem) async {
        guard accessToken != nil else {
            errorMessage = "No access token available"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                await setSubmittingError("Failed to load photo")
                return
            }
            
            // Convert data to UIImage to get dimensions and process
            guard let image = UIImage(data: data) else {
                await setSubmittingError("Failed to process image")
                return
            }
            
            // Get image dimensions
            let size = image.size
            let imageWidth = Int(size.width)
            let imageHeight = Int(size.height)
            
            // Generate filename with timestamp
            let originalName = "photo-\(Int(Date().timeIntervalSince1970)).jpg"
            
            // Convert to JPEG data for upload
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                await MainActor.run {
                    errorMessage = "Failed to process image"
                    isSubmitting = false
                }
                return
            }
            
            // Upload the image using existing uploadImage function
            let newItem = try await BinAPI.shared.addFileItem(
                fileData: jpegData,
                originalName: originalName,
                contentType: "image/jpeg",
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
    private func showSnackbar(message: String, type: MessageType) {
        snackbarMessage = message
        snackbarType = type
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            snackbarMessage = nil
            snackbarType = nil
        }
    }
    
    private func loadBinItems() {
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
    
    private func refreshBinItems() async {
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
    
    private func deleteItem(_ item: BinItem) {
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
    
    private func deleteItemById(_ itemId: String) {
        if let item = binItems.first(where: { $0.id == itemId }) {
            // Store the item for potential restoration
            deletedItems.append(item)
            // Remove from the main list
            binItems.removeAll { $0.id == itemId }
        }
    }
    
    private func restoreItem(_ item: BinItem) {
        // Remove from deleted items and add back to main list
        deletedItems.removeAll { $0.id == item.id }
        binItems.append(item)
        // Sort to maintain order (you might want to insert at the original position)
        binItems.sort { $0.createdAt > $1.createdAt }
    }

    // MARK: - @MainActor UI helpers
    @MainActor
    private func setSubmittingError(_ message: String) async {
        errorMessage = message
        isSubmitting = false
    }

    @MainActor
    private func insertNewItemAndFinishSubmitting(_ newItem: BinItem, resetSelection: Bool = false) async {
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
    private func resetPhotoSelection() async {
        selectedPhoto = nil
    }

    @MainActor
    private func setLoadedItems(_ items: [BinItem]) async {
        binItems = items
        isLoading = false
    }

    @MainActor
    private func setLoadingError(_ message: String) async {
        errorMessage = message
        isLoading = false
    }

    @MainActor
    private func setRefreshedItems(_ items: [BinItem]) async {
        binItems = items
        errorMessage = nil
    }

    @MainActor
    private func setRefreshError(_ message: String) async {
        errorMessage = message
    }

    @MainActor
    private func removeItemById(_ id: String) async {
        binItems.removeAll { $0.id == id }
    }
}

struct SnackbarView: View {
    let message: String
    let type: MessageType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(type == .success ? .green : .red)
                .font(.system(size: 16, weight: .medium))
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            Button("Dismiss") {
                onDismiss()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(type == .success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}


// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}



#Preview {
    BinView(accessToken: nil, onLogout: {})
}
