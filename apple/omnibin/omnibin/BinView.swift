import SwiftUI
import UIKit
import PhotosUI

struct BinView: View {
    let accessToken: String?
    let onLogout: () -> Void
    
    @State private var binItems: [BinItem] = []
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
                    
                    Button("Logout") {
                        onLogout()
                    }
                    .foregroundColor(AppColors.Button.accentPrimary)
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
            .frame(maxWidth: min(geometry.size.width, 600), maxHeight: .infinity)
        }
        .refreshable {
            await refreshBinItems()
        }
        .onAppear {
            loadBinItems()
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
                    await MainActor.run {
                        errorMessage = "No content found in clipboard"
                        isSubmitting = false
                    }
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) async {
        do {
            // Convert image to data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                await MainActor.run {
                    errorMessage = "Failed to process image"
                    isSubmitting = false
                }
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
            
            await MainActor.run {
                binItems.insert(newItem, at: 0)
                isSubmitting = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
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
                await MainActor.run {
                    errorMessage = "No text content to add"
                    isSubmitting = false
                }
                return
            }
            
            if trimmedText.count > maxCharLimit {
                await MainActor.run {
                    errorMessage = "Text content (\(trimmedText.count) characters) exceeds the \(maxCharLimit) character limit"
                    isSubmitting = false
                }
                return
            }
            
            let newItem = try await BinAPI.shared.addTextItem(content: trimmedText, accessToken: accessToken!)
            
            await MainActor.run {
                binItems.insert(newItem, at: 0)
                isSubmitting = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
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
                await MainActor.run {
                    errorMessage = "Failed to load photo"
                    isSubmitting = false
                }
                return
            }
            
            // Convert data to UIImage to get dimensions and process
            guard let image = UIImage(data: data) else {
                await MainActor.run {
                    errorMessage = "Failed to process image"
                    isSubmitting = false
                }
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
            
            await MainActor.run {
                binItems.insert(newItem, at: 0)
                isSubmitting = false
                selectedPhoto = nil // Reset selection
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isSubmitting = false
                selectedPhoto = nil // Reset selection
            }
        }
    }
    
    private func showSnackbar(message: String, type: MessageType) {
        snackbarMessage = message
        snackbarType = type
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
                await MainActor.run {
                    binItems = items
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func refreshBinItems() async {
        guard let token = accessToken else {
            await MainActor.run {
                errorMessage = "No access token available"
            }
            return
        }
        
        do {
            let items = try await BinAPI.shared.fetchBinItems(accessToken: token)
            await MainActor.run {
                binItems = items
                errorMessage = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
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
                await MainActor.run {
                    binItems.removeAll { $0.id == item.id }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func deleteItemById(_ itemId: String) {
        binItems.removeAll { $0.id == itemId }
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
