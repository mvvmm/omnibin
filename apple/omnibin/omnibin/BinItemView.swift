import SwiftUI
import UIKit
import UniformTypeIdentifiers

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
    let onRestore: (() -> Void)?
    let onShowMessage: (String, MessageType) -> Void
    
    @State private var isCopied = false
    @State private var isDownloading = false
    @State private var isCopying = false
    @State private var isExpanded = false
    @State private var showPermissionAlert = false
    @State private var isSaved = false
    @State private var fileDataToSave: Data?
    @State private var fileNameToSave: String?
    @State private var imageSaveHandler: ImageSaveHandler?
    @State private var showExporter = false
    @State private var exportDoc: DataDoc?
    @State private var exportType: UTType = .data
    @State private var exportName: String = "download"
    @State private var urlOG: BinAPI.OGData?
    @Environment(\.colorScheme) private var colorScheme
    
    private let itemId: String
    
    init(item: BinItem, accessToken: String?, onDelete: @escaping () -> Void, onRestore: (() -> Void)? = nil, onShowMessage: @escaping (String, MessageType) -> Void) {
        self.item = item
        self.accessToken = accessToken
        self.onDelete = onDelete
        self.onRestore = onRestore
        self.onShowMessage = onShowMessage
        self.itemId = item.id
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header section with tap gesture
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
            
            // Image preview for image files (separate from tappable header)
            if item.isFile, let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                ImagePreviewView(item: item, accessToken: accessToken, isDarkMode: isDarkMode)
                    .frame(height: 200)
                    .clipped()
                    .contentShape(RoundedRectangle(cornerRadius: 8)) // Define tappable area to match visual bounds
            }

            // URL preview for text items using web OG endpoint
            if item.isText, let textItem = item.textItem {
                URLPreviewView(text: textItem.content, accessToken: accessToken, isDarkMode: isDarkMode, ogOut: $urlOG)
            }
            
            // Action buttons section (only visible when expanded)
            if isExpanded {
                HStack(spacing: 12) {
                    // Copy button
                    Button(action: copyItem) {
                        HStack {
                            if isCopying {
                                ProgressView()
                                    .frame(width: 18, height: 18)
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                            } else {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 18, weight: .medium))
                            }
                            Text(isCopied ? "Copied" : "Copy")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isCopied ? 
                                    Color.green.opacity(isDarkMode ? 0.3 : 0.2) : 
                                    AppColors.Button.accentPrimary.opacity(isDarkMode ? 0.25 : 0.15)
                                )
                        )
                    }
                    .disabled(isDownloading || isCopying)
                    
                    // Download button (for images - save to Photos)
                    if item.isFile, let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                        Button(action: { Task { await downloadItem() } }) {
                            HStack {
                                if isDownloading {
                                    ProgressView()
                                        .frame(width: 18, height: 18)
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                                } else {
                                    Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                        .font(.system(size: 18, weight: .medium))
                                }
                                Text(isSaved ? "Saved" : "Save")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
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
                        }
                        .disabled(isDownloading)
                    }
                    
                    // Download button (for non-images - save to Documents)
                    if item.isFile, let fileItem = item.fileItem, !fileItem.contentType.hasPrefix("image/") {
                        Button(action: { Task { await downloadItem() } }) {
                            HStack {
                                if isDownloading {
                                    ProgressView()
                                        .frame(width: 18, height: 18)
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                                } else {
                                    Image(systemName: "arrow.down.doc")
                                        .font(.system(size: 18, weight: .medium))
                                }
                                Text("Save")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColors.Button.accentSecondary.opacity(isDarkMode ? 0.25 : 0.15))
                            )
                        }
                        .disabled(isDownloading)
                    }
                    
                    // Delete button
                    Button(action: deleteItem) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                            Text("Delete")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(isDarkMode ? 0.25 : 0.15))
                        )
                    }
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
        .fileExporter(isPresented: $showExporter,
                      document: exportDoc,
                      contentType: exportType,
                      defaultFilename: exportName) { result in
            switch result {
            case .success: showSuccessMessage("Saved to Files")
            case .failure: onShowMessage("Failed to save file", .error)
            }
            isDownloading = false
        }
        .onChange(of: showExporter) { oldValue, newValue in
            if newValue == false {
                // Ensure loading state is reset when the exporter closes (including cancel)
                isDownloading = false
            }
        }
    }
    
    private var itemTitle: String {
        if item.isText, let textItem = item.textItem {
            // If the text is a URL and we have OG data, prefer OG title (like web)
            if let _ = firstURL(in: textItem.content) {
                if let title = urlOG?.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return title
                }
            }
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
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                isCopied = false
            }
        } else if item.isFile {
            isCopying = true
            Task { await copyFileToClipboard() }
        }
    }
    
    private func showSuccessMessage(_ message: String) {
        onShowMessage(message, .success)
    }
    
    private func copyFileToClipboard() async {
        guard let token = accessToken else { return }
        do {
            let downloadURL = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
            guard let url = URL(string: downloadURL) else {
                await setCopyErrorUI(message: "Invalid download URL")
                return
            }
            let isImage = item.fileItem?.contentType.hasPrefix("image/") == true
            if isImage {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await completeImageCopySuccess(image)
                } else {
                    await setCopyErrorUI(message: nil)
                }
            } else {
                let (tmpURL, _) = try await URLSession.shared.download(from: url)
                let filename = item.fileItem?.originalName ?? "file"
                await completeFileCopyFromDownloadedURL(tmpURL: tmpURL, filename: filename)
            }
        } catch {
            await setCopyErrorUI(message: "Failed to copy file: \(error.localizedDescription)")
        }
    }
    
    private func downloadItem() async {
        guard item.isFile, let token = accessToken else { return }
        isDownloading = true
        do {
            let downloadURL = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
            if item.fileItem?.contentType.hasPrefix("image/") == true {
                // Save images (e.g., PNG, JPEG) directly to Photos
                let (data, _) = try await URLSession.shared.data(from: URL(string: downloadURL)!)
                if let image = UIImage(data: data) {
                    await saveImageToPhotos(image)
                } else {
                    await setDownloadErrorUI(message: "Failed to decode image")
                }
            } else {
                // Non-images: present Files exporter
                let (tmp, _) = try await URLSession.shared.download(from: URL(string: downloadURL)!)
                let data = try Data(contentsOf: tmp)
                let name = item.fileItem?.originalName ?? "download"
                let ext  = (name as NSString).pathExtension
                let type = UTType(filenameExtension: ext) ?? .data

                await MainActor.run {
                    exportType = type
                    exportName = name.isEmpty ? "download" : name
                    exportDoc  = DataDoc(data: data)
                    showExporter = true
                }
            }
        } catch {
            await setDownloadErrorUI(message: "Failed: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func handleImageSaveCompletion(error: Error?) {
        // UIKit calls this completion on the main thread; update UI directly
        self.isDownloading = false
        
        if let error = error {
            if error.localizedDescription.contains("permission") || error.localizedDescription.contains("denied") {
                self.showPermissionAlert = true
            } else {
                self.onShowMessage("Failed to save image: \(error.localizedDescription)", .error)
            }
        } else {
            self.isSaved = true
            self.showSuccessMessage("Image saved to Photos")
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self.isSaved = false
            }
        }
        // Release strong reference to the handler
        self.imageSaveHandler = nil
    }

    @MainActor
    private func completeImageCopySuccess(_ image: UIImage) async {
        UIPasteboard.general.image = image
        isCopying = false
        isCopied = true
        showSuccessMessage("Image copied to clipboard")
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        isCopied = false
    }

    @MainActor
    private func completeFileCopyFromDownloadedURL(tmpURL: URL, filename: String) async {
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

            UIPasteboard.general.setItemProviders([provider], localOnly: false, expirationDate: Date().addingTimeInterval(3600))
            isCopying = false
            isCopied = true
            showSuccessMessage("File copied to clipboard")
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            isCopied = false
        } catch {
            isCopying = false
            onShowMessage("Failed to copy file: \(error.localizedDescription)", .error)
        }
    }

    @MainActor
    private func setCopyErrorUI(message: String?) async {
        isCopying = false
        if let message = message {
            onShowMessage(message, .error)
        }
    }

    @MainActor
    private func saveImageToPhotos(_ image: UIImage) async {
        let handler = ImageSaveHandler { error in
            self.handleImageSaveCompletion(error: error)
        }
        // Keep a strong reference until completion
        self.imageSaveHandler = handler
        UIImageWriteToSavedPhotosAlbum(image, handler, #selector(ImageSaveHandler.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @MainActor
    private func setDownloadErrorUI(message: String) async {
        isDownloading = false
        onShowMessage(message, .error)
    }
    
    private func deleteItem() {
        guard let token = accessToken else {
            onShowMessage("No access token available", .error)
            return
        }
        
        // Optimistic delete - remove from UI immediately
        onDelete()
        
        // Make API call in background
        Task {
            do {
                try await BinAPI.shared.deleteItem(itemId: item.id, accessToken: token)
                // Success - item is already removed from UI
            } catch {
                // Error - restore the item to UI
                await restoreDeletedItemUI(error: error)
            }
        }
    }

    @MainActor
    private func restoreDeletedItemUI(error: Error) async {
        onShowMessage("Failed to delete item: \(error.localizedDescription)", .error)
        onRestore?()
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
        // Use a fixed-size container to strictly limit the hit testing area
        Rectangle()
            .fill(Color.clear)
            .frame(height: 200)
            .overlay(
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
                                .contentShape(RoundedRectangle(cornerRadius: 8)) // Define tappable area to match visual bounds
                        .contextMenu {
                            if let downloadedImage = downloadedImage {
                                Button(action: {
                                    Task { @MainActor in
                                        UIImageWriteToSavedPhotosAlbum(downloadedImage, nil, nil, nil)
                                    }
                                }) {
                                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                                }
                                
                                Button(action: {
                                    Task { @MainActor in
                                        UIPasteboard.general.image = downloadedImage
                                    }
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                
                                Button(action: {
                                    Task { @MainActor in
                                        // Share sheet
                                        let activityVC = UIActivityViewController(activityItems: [downloadedImage], applicationActivities: nil)
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let window = windowScene.windows.first {
                                            window.rootViewController?.present(activityVC, animated: true)
                                        }
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
            )
            .clipped() // Final clipping to ensure hit testing area is exactly the rectangle bounds
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
                await setImageURLLoaded(url)
            } catch {
                await setImageURLError()
            }
        }
    }
    
    private func downloadImageForContextMenu(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await setDownloadedImage(image)
                }
            } catch {
                // Silently fail for context menu image download
            }
        }
    }

    // MARK: - ImagePreviewView MainActor helpers
    @MainActor
    private func setImageURLLoaded(_ url: String) async {
        imageURL = url
        isLoading = false
    }

    @MainActor
    private func setImageURLError() async {
        hasError = true
        isLoading = false
    }

    @MainActor
    private func setDownloadedImage(_ image: UIImage) async {
        downloadedImage = image
    }
}

// MARK: - URL Preview View (Open Graph)
struct URLPreviewView: View {
    let text: String
    let accessToken: String?
    let isDarkMode: Bool
    @Binding var ogOut: BinAPI.OGData?

    @State private var og: BinAPI.OGData?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let urlString = extractFirstURL(from: text), let url = URL(string: urlString) {
                // If we have OG, render image + text; otherwise render compact text card
                if let og = og {
                VStack(alignment: .leading, spacing: 0) {
                    // Determine a valid image URL if provided
                    let trimmedImage = og.image?.trimmingCharacters(in: .whitespacesAndNewlines)
                    let imageURL = (trimmedImage?.isEmpty == false) ? URL(string: trimmedImage!) : nil
                    if let imageURL = imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                                .frame(height: 200)
                        }
                    }
                    // Title/description row. Only show favicon when there is no image.
                    HStack(alignment: .center, spacing: 10) {
                        if imageURL == nil, let iconURL = faviconURL(for: url, og: og) {
                            AsyncImage(url: iconURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(4)
                            } placeholder: {
                                Rectangle()
                                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.25))
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(4)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                        Text((og.title?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? (url.host ?? url.absoluteString))
                            .font(.headline)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                            .lineLimit(2)
                        if let desc = og.description?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                                .lineLimit(3)
                        }
                        Text((og.siteName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? (url.host ?? ""))
                            .font(.caption)
                            .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight])
                            .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                )
                .onTapGesture {
                    UIApplication.shared.open(url)
                }
                } else if isLoading {
                    Rectangle()
                        .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.2))
                        .frame(height: 60)
                        .overlay(ProgressView().scaleEffect(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    // Compact fallback when no OG available
                    HStack(alignment: .center, spacing: 10) {
                        if let iconURL = faviconURL(for: url, og: nil) {
                            AsyncImage(url: iconURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(4)
                            } placeholder: {
                                Rectangle()
                                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.25))
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(4)
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(url.host ?? url.absoluteString)
                                .font(.headline)
                                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                .lineLimit(1)
                            Text(url.absoluteString)
                                .font(.caption)
                                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                            )
                    )
                    .onTapGesture { UIApplication.shared.open(url) }
                }
            }
        }
        .onAppear { Task { await loadOGIfNeeded() } }
    }

    private func extractFirstURL(from text: String) -> String? {
        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try? NSDataDetector(types: types.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let match = detector?.firstMatch(in: text, options: [], range: range)
        if let r = match?.range, let swiftRange = Range(r, in: text) {
            return String(text[swiftRange])
        }
        return nil
    }

    private func loadOGIfNeeded() async {
        guard let token = accessToken, !token.isEmpty else { return }
        guard let url = extractFirstURL(from: text) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if let data = try await BinAPI.shared.fetchOpenGraph(url: url, accessToken: token) {
                await MainActor.run { self.og = data; self.ogOut = data }
            }
        } catch {
            // ignore; show nothing if OG fails
        }
    }
}

// MARK: - Helpers
private func firstURL(in text: String) -> String? {
    let types: NSTextCheckingResult.CheckingType = .link
    let detector = try? NSDataDetector(types: types.rawValue)
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    let match = detector?.firstMatch(in: text, options: [], range: range)
    if let r = match?.range, let swiftRange = Range(r, in: text) {
        return String(text[swiftRange])
    }
    return nil
}

private func faviconURL(for pageURL: URL, og: BinAPI.OGData?) -> URL? {
    if let icon = og?.icon, let iconURL = URL(string: icon) { return iconURL }
    var comps = URLComponents()
    comps.scheme = pageURL.scheme
    comps.host = pageURL.host
    comps.port = pageURL.port
    comps.path = "/favicon.ico"
    return comps.url
}

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
