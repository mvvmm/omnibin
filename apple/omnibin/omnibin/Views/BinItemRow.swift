import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct BinItemRow: View {
    let item: BinItem
    let accessToken: String?
    let columnWidth: CGFloat
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
    @State private var isOGLoading = true
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var isSharing = false
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var binItemService = BinItemService()
    @StateObject private var imageService = ImageService()
    
    private let itemId: String
    
    init(item: BinItem, accessToken: String?, columnWidth: CGFloat, onDelete: @escaping () -> Void, onRestore: (() -> Void)? = nil) {
        self.item = item
        self.accessToken = accessToken
        self.columnWidth = columnWidth
        self.onDelete = onDelete
        self.onRestore = onRestore
        self.itemId = item.id
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: item.isText && !isLink ? .top : .center, spacing: 8) {
                BinItemHeader(content: headerKind, isDarkMode: isDarkMode)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: isIPad ? 17 : 14, weight: .medium))
                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .frame(width: 40, height: 44)
            }
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(isExpanded ? "Hides actions" : "Shows actions")

            if isExpanded {
                BinItemActionRow(
                    isCopied: isCopied,
                    isCopying: isCopying,
                    isSharing: isSharing,
                    showsSave: item.isFile && item.fileItem != nil,
                    isSaved: isSaved,
                    isDownloading: isDownloading,
                    isDarkMode: isDarkMode,
                    onCopy: copyItem,
                    onShare: { Task { await shareItem() } },
                    onSave: { Task { await downloadItem() } },
                    onDelete: deleteItem
                )
                    .padding(.horizontal, 12)
                    .padding(.top, 2)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if item.isFile, let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                ImagePreviewView(item: item, accessToken: accessToken, isDarkMode: isDarkMode, availableWidth: columnWidth)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }

            if item.isText, let textItem = item.textItem {
                URLPreviewView(
                    text: textItem.content,
                    accessToken: accessToken,
                    isDarkMode: isDarkMode,
                    availableWidth: columnWidth,
                    ogData: convertTextItemToOGData(textItem),
                    ogDataFetched: textItem.ogDataFetched ?? false,
                    ogOut: $urlOG,
                    isOGLoading: $isOGLoading
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppColors.surface(isDarkMode: isDarkMode))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(AppColors.border(isDarkMode: isDarkMode), lineWidth: 1)
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
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: shareItems, isPresented: $showShareSheet)
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
    
    private var isLink: Bool {
        guard item.isText, let textItem = item.textItem else { return false }
        return firstURL(in: textItem.content) != nil
    }

    private var linkHost: String? {
        guard item.isText, let textItem = item.textItem, let raw = firstURL(in: textItem.content) else { return nil }
        return URL(string: normalizeURLString(raw))?.host
    }

    private var headerKind: BinItemHeader.Content {
        if isLink && isOGLoading && urlOG?.title == nil {
            return .loadingLink
        }
        if isLink {
            return .link(title: itemTitle, host: linkHost == itemTitle ? nil : linkHost)
        }
        if item.isFile, let fileItem = item.fileItem {
            return fileItem.contentType.hasPrefix("image/")
                ? .imageFile(name: fileItem.originalName)
                : .file(name: fileItem.originalName)
        }
        return .text(itemTitle)
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
    
    private func shareItem() async {
        isSharing = true
        let result = await binItemService.prepareShareContent(item: item, accessToken: accessToken)
        
        await MainActor.run {
            isSharing = false
            if result.success, let items = result.shareItems {
                shareItems = items
                showShareSheet = true
            }
        }
    }
    
    private func convertTextItemToOGData(_ textItem: TextItem) -> OGData? {
        // If OG data hasn't been fetched yet, return nil
        guard textItem.ogDataFetched == true else { return nil }
        
        // If all OG fields are nil, return nil (no OG data available)
        if textItem.ogTitle == nil &&
           textItem.ogDescription == nil &&
           textItem.ogImage == nil &&
           textItem.ogIcon == nil &&
           textItem.ogSiteName == nil {
            return nil
        }
        
        // Convert textItem OG fields to OGData
        return OGData(
            url: firstURL(in: textItem.content),
            title: textItem.ogTitle,
            description: textItem.ogDescription,
            image: textItem.ogImage,
            imageWidth: textItem.ogImageWidth,
            imageHeight: textItem.ogImageHeight,
            icon: textItem.ogIcon,
            siteName: textItem.ogSiteName
        )
    }
}

// MARK: - Bin Item Header
private struct BinItemHeader: View {
    enum Content: Equatable {
        case loadingLink
        case link(title: String, host: String?)
        case imageFile(name: String)
        case file(name: String)
        case text(String)
    }

    let content: Content
    let isDarkMode: Bool

    var body: some View {
        switch content {
        case .loadingLink:
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: 200, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: 90, height: 11)
            }
            .padding(.vertical, 12)
        case .link(let title, let host):
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: isIPad ? 19 : 16))
                    .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    .lineLimit(1)
                if let host {
                    Text(host)
                        .font(.system(size: isIPad ? 16 : 13))
                        .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 9)
        case .imageFile(let name):
            Text(name)
                .font(.system(size: isIPad ? 17 : 14))
                .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                .lineLimit(1)
                .padding(.vertical, 12)
        case .file(let name):
            HStack(spacing: 10) {
                Image(systemName: "doc")
                    .font(.system(size: isIPad ? 19 : 16))
                    .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                Text(name)
                    .font(.system(size: isIPad ? 19 : 16))
                    .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
        case .text(let text):
            Text(text)
                .font(.system(size: isIPad ? 19 : 16))
                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                .lineLimit(5)
                .padding(.vertical, 12)
        }
    }
}

// MARK: - Bin Item Action Row
private struct BinItemActionRow: View {
    let isCopied: Bool
    let isCopying: Bool
    let isSharing: Bool
    let showsSave: Bool
    let isSaved: Bool
    let isDownloading: Bool
    let isDarkMode: Bool
    let onCopy: () -> Void
    let onShare: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ItemActionButton(
                title: isCopied ? "Copied" : "Copy",
                systemImage: isCopied ? "checkmark" : "doc.on.doc",
                isLoading: isCopying,
                foreground: isCopied ? AppColors.accentInk(isDarkMode: isDarkMode) : AppColors.primaryText(isDarkMode: isDarkMode),
                background: isCopied ? AppColors.copiedBackground(isDarkMode: isDarkMode) : AppColors.actionBackground(isDarkMode: isDarkMode),
                action: onCopy
            )
            .disabled(isDownloading || isCopying)

            ItemActionButton(
                title: "Share",
                systemImage: "square.and.arrow.up",
                isLoading: isSharing,
                foreground: AppColors.primaryText(isDarkMode: isDarkMode),
                background: AppColors.actionBackground(isDarkMode: isDarkMode),
                action: onShare
            )
            .disabled(isSharing)

            if showsSave {
                ItemActionButton(
                    title: isSaved ? "Saved" : "Save",
                    systemImage: isSaved ? "checkmark" : "square.and.arrow.down",
                    isLoading: isDownloading,
                    foreground: isSaved ? AppColors.accentInk(isDarkMode: isDarkMode) : AppColors.primaryText(isDarkMode: isDarkMode),
                    background: isSaved ? AppColors.copiedBackground(isDarkMode: isDarkMode) : AppColors.actionBackground(isDarkMode: isDarkMode),
                    action: onSave
                )
                .disabled(isDownloading)
            }

            ItemActionButton(
                title: "Delete",
                systemImage: "trash",
                isLoading: false,
                foreground: AppColors.danger(isDarkMode: isDarkMode),
                background: AppColors.dangerBackground(isDarkMode: isDarkMode),
                action: onDelete
            )
        }
    }
}

// MARK: - Item Action Button
private struct ItemActionButton: View {
    let title: String
    let systemImage: String
    let isLoading: Bool
    let foreground: Color
    let background: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                        .frame(height: 18)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: isIPad ? 20 : 17, weight: .medium))
                        .frame(height: 18)
                }
                Text(title)
                    .font(.system(size: isIPad ? 15 : 13, weight: .medium))
            }
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 64 : 52)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(background)
            )
        }
        .buttonStyle(.plain)
    }
}
