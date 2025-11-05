import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct BinItemRow: View {
    let item: BinItem
    let accessToken: String?
    let onDelete: () -> Void
    let onRestore: (() -> Void)?
    
    @State private var isCopied = false
    @State private var isDownloading = false
    @State private var isCopying = false
    @State private var isExpanded = false
    @State private var showPermissionAlert = false
    @State private var isSaved = false
    @State private var showExporter = false
    @State private var exportDoc: DataDoc?
    @State private var exportType: UTType = .data
    @State private var exportName: String = "download"
    @State private var urlOG: OGData?
    @State private var isOGLoading = false
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var binItemService = BinItemService()
    @StateObject private var imageService = ImageService()
    
    private let itemId: String
    
    init(item: BinItem, accessToken: String?, onDelete: @escaping () -> Void, onRestore: (() -> Void)? = nil) {
        self.item = item
        self.accessToken = accessToken
        self.onDelete = onDelete
        self.onRestore = onRestore
        self.itemId = item.id
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section with tap gesture
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if item.isText, let textItem = item.textItem, let _ = firstURL(in: textItem.content), isOGLoading {
                        // Show skeleton when loading OG data for URL
                        Rectangle()
                            .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                            .frame(height: 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cornerRadius(4)
                    } else {
                        Text(itemTitle)
                            .font(isIPad ? .system(size: 24, weight: .semibold) : .headline)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                            .lineLimit(item.isText ? 5 : 1)
                    }
                }
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.down")
                    .font(.system(size: isIPad ? 24 : 14, weight: .medium))
                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            // Image preview for image files (separate from tappable header) - full width, no padding
            if item.isFile, let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                ImagePreviewView(item: item, accessToken: accessToken, isDarkMode: isDarkMode)
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 350 : 200)
                    .contentShape(Rectangle()) // Define tappable area to match visual bounds
                    .padding(.top, 8) // mt-2 from web
                    .padding(.bottom, 16) // mb-4 from web
            }

            // URL preview for text items using web OG endpoint - full width, no padding
            if item.isText, let textItem = item.textItem {
                URLPreviewView(text: textItem.content, accessToken: accessToken, isDarkMode: isDarkMode, ogOut: $urlOG, isOGLoading: $isOGLoading)
                    .padding(.top, 8) // mt-2 from web
                    .padding(.bottom, urlOG?.image == nil ? 16 : 0) // mb-4 from web (only when no image)
            }
            
            // Metadata section - displayed below image/preview like web
            Text(itemSubtitle)
                .font(isIPad ? .system(size: 17) : .caption)
                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                .padding(.horizontal, 16)
                .padding(.top, 4) // mt-1 from web
                .padding(.bottom, 0)
            
            // Action buttons section (only visible when expanded)
            if isExpanded {
                HStack(spacing: 12) {
                    // Copy button
                    Button(action: copyItem) {
                        HStack {
                            if isCopying {
                                ProgressView()
                                    .frame(width: isIPad ? 23 : 18, height: isIPad ? 23 : 18)
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                            } else {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: isIPad ? 23 : 18, weight: .medium))
                            }
                            Text(isCopied ? "Copied" : "Copy")
                                .font(.system(size: isIPad ? 24 : 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: isIPad ? 66 : 44, maxHeight: isIPad ? 66 : 44)
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
                                        .frame(width: isIPad ? 23 : 18, height: isIPad ? 23 : 18)
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                                } else {
                                    Image(systemName: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                        .font(.system(size: isIPad ? 23 : 18, weight: .medium))
                                }
                                Text(isSaved ? "Saved" : "Save")
                                    .font(.system(size: isIPad ? 24 : 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity, minHeight: isIPad ? 66 : 44, maxHeight: isIPad ? 66 : 44)
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
                                        .frame(width: isIPad ? 23 : 18, height: isIPad ? 23 : 18)
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryText(isDarkMode: isDarkMode)))
                                } else {
                                    Image(systemName: "arrow.down.doc")
                                        .font(.system(size: isIPad ? 23 : 18, weight: .medium))
                                }
                                Text("Save")
                                    .font(.system(size: isIPad ? 24 : 14, weight: .medium))
                            }
                            .frame(maxWidth: .infinity, minHeight: isIPad ? 66 : 44, maxHeight: isIPad ? 66 : 44)
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
                                .font(.system(size: isIPad ? 23 : 18, weight: .medium))
                            Text("Delete")
                                .font(.system(size: isIPad ? 24 : 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: isIPad ? 66 : 44, maxHeight: isIPad ? 66 : 44)
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(isDarkMode ? 0.25 : 0.15))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16) // Add top spacing to buttons
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
        }
        .padding(.bottom, 16) // Add bottom spacing to entire card
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
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
            case .failure: break
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
            if let urlString = firstURL(in: textItem.content) {
                if let title = urlOG?.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return title
                }
                // If we're loading OG data for a URL, show the raw URL (skeleton will be shown in UI)
                if isOGLoading {
                    return textItem.content
                }
                // If OG data failed to load or doesn't exist, show hostname instead of raw URL
                let normalizedURL = normalizeURLString(urlString)
                if let url = URL(string: normalizedURL) {
                    return url.host ?? url.absoluteString
                }
                // Fallback: try to extract hostname from the raw string
                if let url = URL(string: urlString) {
                    return url.host ?? url.absoluteString
                }
            }
            return textItem.content
        } else if item.isFile, let fileItem = item.fileItem {
            return fileItem.originalName
        }
        return ""
    }
    
    private func normalizeURLString(_ raw: String) -> String {
        // Ensure we have an absolute URL with a scheme. Default to https.
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("http://") || s.hasPrefix("https://") { return s }
        if s.hasPrefix("//") { return "https:" + s }
        if s.hasPrefix("www.") { return "https://" + s }
        // If no scheme and not starting with www, still try https
        return "https://" + s
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
        isCopying = true
        Task {
            let result = await binItemService.copyItem(item: item, accessToken: accessToken)
            await MainActor.run {
                isCopying = false
                if result.success {
                    isCopied = true
                    showSuccessMessage(result.message)
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        isCopied = false
                    }
                } else {
                    // Error occurred but no snackbar shown
                }
            }
        }
    }
    
    private func downloadItem() async {
        isDownloading = true
        let result = await binItemService.downloadItem(item: item, accessToken: accessToken)
        
        if result.success {
            if let (data, name, type) = result.exportData {
                if item.fileItem?.contentType.hasPrefix("image/") == true {
                    // Save image to Photos
                    if let image = UIImage(data: data) {
                        imageService.saveImageToPhotos(image) { error in
                            Task { @MainActor in
                                if let error = error {
                                    if error.localizedDescription.contains("permission") || error.localizedDescription.contains("denied") {
                                        showPermissionAlert = true
                                    } else {
                                        // Error occurred but no snackbar shown
                                    }
                                } else {
                                    isSaved = true
                                    showSuccessMessage("Image saved to Photos")
                                    Task { @MainActor in
                                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                                        isSaved = false
                                    }
                                }
                                isDownloading = false
                            }
                        }
                    } else {
                        await MainActor.run {
                            isDownloading = false
                            // Error occurred but no snackbar shown
                        }
                    }
                } else {
                    // Present file exporter
                    await MainActor.run {
                        exportType = type
                        exportName = name.isEmpty ? "download" : name
                        exportDoc = DataDoc(data: data)
                        showExporter = true
                    }
                }
            }
        } else {
            await MainActor.run {
                isDownloading = false
                // Error occurred but no snackbar shown
            }
        }
    }
    
    private func showSuccessMessage(_ message: String) {
        // Success message functionality removed
    }
    
    private func deleteItem() {
        guard accessToken != nil else {
            return
        }
        
        // Optimistic delete - remove from UI immediately
        onDelete()
        
        // Make API call in background
        Task {
            let result = await binItemService.deleteItem(item: item, accessToken: accessToken)
            if !result.success {
                await MainActor.run {
                    onRestore?()
                }
            }
        }
    }
}
