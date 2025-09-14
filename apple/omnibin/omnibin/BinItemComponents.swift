import SwiftUI
import UIKit

enum MessageType {
    case success
    case error
}

// Helper class to handle UIImageWriteToSavedPhotosAlbum completion callback
class ImageSaveHandler: NSObject {
    var completion: (Error?) -> Void
    
    init(completion: @escaping (Error?) -> Void) {
        self.completion = completion
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completion(error)
    }
}

struct BinItemRow: View {
    let item: BinItem
    let accessToken: String?
    let onDelete: () -> Void
    let onShowMessage: (String, MessageType) -> Void
    
    @State private var isCopied = false
    @State private var isDownloading = false
    @State private var isCopying = false
    @State private var isExpanded = false
    @State private var showPermissionAlert = false
    @State private var isSaved = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let itemId: String
    
    init(item: BinItem, accessToken: String?, onDelete: @escaping () -> Void, onShowMessage: @escaping (String, MessageType) -> Void) {
        self.item = item
        self.accessToken = accessToken
        self.onDelete = onDelete
        self.onShowMessage = onShowMessage
        self.itemId = item.id
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content section with tap gesture
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(itemTitle)
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                            .lineLimit(2)
                        
                        Text(itemSubtitle)
                            .font(.caption)
                            .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                    }
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
                
                // Image preview for image files
                if item.isFile, let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                    ImagePreviewView(item: item, accessToken: accessToken, isDarkMode: isDarkMode)
                }
            }
            
            // Action buttons section (only visible when expanded)
            if isExpanded {
                HStack(spacing: 12) {
                    // Copy button
                    Button(action: copyItem) {
                        if isCopying {
                            ProgressView()
                                .frame(width: 18, height: 18)
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                        } else {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                    .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCopied ? 
                                Color.green.opacity(isDarkMode ? 0.3 : 0.2) : 
                                AppColors.Button.accentPrimary.opacity(isDarkMode ? 0.25 : 0.15)
                            )
                    )
                    .disabled(isDownloading || isCopying)
                    
                    // Download button (for images - save to Photos)
                    if item.isFile, let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                        Button(action: downloadItem) {
                            if isDownloading {
                                ProgressView()
                                    .frame(width: 18, height: 18)
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                            } else {
                                Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                    .font(.system(size: 18, weight: .medium))
                            }
                        }
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSaved ? 
                                    Color.green.opacity(isDarkMode ? 0.3 : 0.2) : 
                                    (isDownloading ? 
                                        Color.green.opacity(isDarkMode ? 0.3 : 0.2) : 
                                        AppColors.Button.accentSecondary.opacity(isDarkMode ? 0.25 : 0.15)
                                    )
                                )
                        )
                        .disabled(isDownloading)
                    }
                    
                    // Download button (for non-images - save to Documents)
                    if item.isFile, let fileItem = item.fileItem, !fileItem.contentType.hasPrefix("image/") {
                        Button(action: downloadItem) {
                            if isDownloading {
                                ProgressView()
                                    .frame(width: 18, height: 18)
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                            } else {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 18, weight: .medium))
                            }
                        }
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.Button.accentSecondary.opacity(isDarkMode ? 0.25 : 0.15))
                        )
                        .disabled(isDownloading)
                    }
                    
                    // Delete button
                    Button(action: deleteItem) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(isDarkMode ? 0.25 : 0.15))
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                )
        )
        .shadow(
            color: AppColors.cardShadow(isDarkMode: isDarkMode),
            radius: 8,
            x: 0,
            y: 4
        )
        .alert("Photos Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To save images to your Photos library, please enable Photos access in Settings > Privacy & Security > Photos > omnibin")
        }
    }
    
    private var itemTitle: String {
        if item.isText, let textItem = item.textItem {
            return textItem.content
        } else if item.isFile, let fileItem = item.fileItem {
            return fileItem.originalName
        }
        return ""
    }
    
    private var itemSubtitle: String {
        var parts: [String] = [item.formattedCreatedAt()]
        
        if item.isText, let textItem = item.textItem {
            parts.append("\(textItem.content.count) chars")
        } else if item.isFile, let fileItem = item.fileItem {
            parts.append(fileItem.contentType)
            parts.append(fileItem.formattedSize())
        }
        
        return parts.joined(separator: " · ")
    }
    
    private func copyItem() {
        if item.isText, let textItem = item.textItem {
            UIPasteboard.general.string = textItem.content
            isCopied = true
            showSuccessMessage("Text copied to clipboard")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isCopied = false
            }
        } else if item.isFile {
            isCopying = true
            copyFileToClipboard()
        }
    }
    
    private func showSuccessMessage(_ message: String) {
        onShowMessage(message, .success)
    }
    
    private func copyFileToClipboard() {
        guard let token = accessToken else { return }
        
        Task {
            do {
                let downloadURL = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
                
                // Download the file
                let (data, _) = try await URLSession.shared.data(from: URL(string: downloadURL)!)
                
                // Check if it's an image
                if let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            UIPasteboard.general.image = image
                            isCopying = false
                            isCopied = true
                            showSuccessMessage("Image copied to clipboard")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isCopied = false
                            }
                        }
                    } else {
                        await MainActor.run {
                            isCopying = false
                        }
                    }
                } else {
                    // For non-image files, copy the file data
                    await MainActor.run {
                        UIPasteboard.general.setData(data, forPasteboardType: item.fileItem?.contentType ?? "public.data")
                        isCopying = false
                        isCopied = true
                        showSuccessMessage("File copied to clipboard")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isCopied = false
                        }
                    }
                }
            } catch {
                // Show error message to user
                await MainActor.run {
                    isCopying = false
                    onShowMessage("Failed to copy file: \(error.localizedDescription)", .error)
                }
            }
        }
    }
    
    private func downloadItem() {
        guard item.isFile, let token = accessToken else { return }
        
        isDownloading = true
        
        Task {
            do {
                let downloadURL = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
                
                // Download the file
                let (data, _) = try await URLSession.shared.data(from: URL(string: downloadURL)!)
                
                // Check if it's an image
                if let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                    if let image = UIImage(data: data) {
                        // Save to Photos library with completion handler
                        await MainActor.run {
                            let handler = ImageSaveHandler { error in
                                self.handleImageSaveCompletion(error: error)
                            }
                            // Keep a strong reference to the handler
                            objc_setAssociatedObject(image, "ImageSaveHandler", handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                            UIImageWriteToSavedPhotosAlbum(image, handler, #selector(ImageSaveHandler.image(_:didFinishSavingWithError:contextInfo:)), nil)
                        }
                    } else {
                        await MainActor.run {
                            isDownloading = false
                            onShowMessage("Failed to process image data", .error)
                        }
                    }
                } else {
                    // For non-image files, save to documents directory
                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileName = item.fileItem?.originalName ?? "download"
                    let fileURL = documentsPath.appendingPathComponent(fileName)
                    
                    try data.write(to: fileURL)
                    
                    await MainActor.run {
                        isDownloading = false
                        showSuccessMessage("File saved to Documents")
                    }
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    onShowMessage("Failed to download file: \(error.localizedDescription)", .error)
                }
            }
        }
    }
    
    private func handleImageSaveCompletion(error: Error?) {
        DispatchQueue.main.async {
            self.isDownloading = false
            
            if let error = error {
                // Check if it's a permission error
                if error.localizedDescription.contains("permission") || error.localizedDescription.contains("denied") {
                    self.showPermissionAlert = true
                } else {
                    // Show other errors as snackbar messages
                    self.onShowMessage("Failed to save image: \(error.localizedDescription)", .error)
                }
            } else {
                // Success - show saved indication
                self.isSaved = true
                self.showSuccessMessage("Image saved to Photos")
                
                // Reset the saved state after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isSaved = false
                }
            }
        }
    }
    
    private func deleteItem() {
        guard let token = accessToken else {
            onShowMessage("No access token available", .error)
            return
        }
        
        Task {
            do {
                try await BinAPI.shared.deleteItem(itemId: item.id, accessToken: token)
                await MainActor.run {
                    onDelete() // Call the parent's delete callback to remove from UI
                }
            } catch {
                await MainActor.run {
                    onShowMessage("Failed to delete item: \(error.localizedDescription)", .error)
                }
            }
        }
    }
}

struct ImagePreviewView: View {
    let item: BinItem
    let accessToken: String?
    let isDarkMode: Bool
    
    @State private var imageURL: String?
    @State private var isLoading = true
    @State private var hasError = false
    @State private var downloadedImage: UIImage?
    
    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
                        )
                        .contextMenu {
                            if let downloadedImage = downloadedImage {
                                Button(action: {
                                    UIImageWriteToSavedPhotosAlbum(downloadedImage, nil, nil, nil)
                                }) {
                                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                                }
                                
                                Button(action: {
                                    UIPasteboard.general.image = downloadedImage
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                
                                Button(action: {
                                    // Share sheet
                                    let activityVC = UIActivityViewController(activityItems: [downloadedImage], applicationActivities: nil)
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first {
                                        window.rootViewController?.present(activityVC, animated: true)
                                    }
                                }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                        .onAppear {
                            // Download the image for context menu actions
                            downloadImageForContextMenu(from: url)
                        }
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
            } else if hasError {
                Rectangle()
                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                            Text("Preview unavailable")
                                .font(.caption)
                                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                        }
                    )
            } else {
                Rectangle()
                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .onAppear {
            loadImageURL()
        }
    }
    
    private func loadImageURL() {
        guard let token = accessToken else {
            hasError = true
            isLoading = false
            return
        }
        
        Task {
            do {
                let url = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
                await MainActor.run {
                    imageURL = url
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    hasError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func downloadImageForContextMenu(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        downloadedImage = image
                    }
                }
            } catch {
                // Silently fail for context menu image download
            }
        }
    }
}
