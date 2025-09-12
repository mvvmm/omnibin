import SwiftUI

struct BinView: View {
    let accessToken: String?
    let onLogout: () -> Void
    
    @State private var binItems: [BinItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var newItemText = ""
    @State private var isSubmitting = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    private let maxCharLimit = 10000
    private let binItemsLimit = 10
    
    var body: some View {
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
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Add new item form
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Paste something...", text: $newItemText, axis: .vertical)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.95, green: 0.95, blue: 0.95))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    newItemText.isEmpty ? 
                                                    (isDarkMode ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color(red: 0.8, green: 0.8, blue: 0.8)) :
                                                    AppColors.Button.accentPrimary,
                                                    lineWidth: newItemText.isEmpty ? 1 : 2
                                                )
                                        )
                                )
                                .foregroundColor(isDarkMode ? .white : .black)
                                .font(.system(size: 16, weight: .regular))
                                .lineLimit(3...6)
                                .onSubmit {
                                    addTextItem()
                                }
                                .onTapGesture {
                                    // Add subtle animation when tapped
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        // This will trigger the border color change
                                    }
                                }
                        }
                        
                        HStack(alignment: .bottom) {
                            Button(action: addTextItem) {
                                HStack(spacing: 8) {
                                    if isSubmitting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Add")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
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
                            .disabled(isSubmitting || newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(isSubmitting || newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isSubmitting || newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            
                            Spacer()
                            
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
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 24)
                    
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
                        LazyVStack(spacing: 12) {
                            ForEach(binItems) { item in
                                BinItemRow(item: item, accessToken: accessToken) {
                                    deleteItem(item)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .refreshable {
            await refreshBinItems()
        }
        .onAppear {
            loadBinItems()
        }
    }
    
    private func addTextItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        if trimmedText.count > maxCharLimit {
            errorMessage = "Text content (\(trimmedText.count) characters) exceeds the \(maxCharLimit) character limit"
            return
        }
        
        guard let token = accessToken else {
            errorMessage = "No access token available"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let newItem = try await BinAPI.shared.addTextItem(content: trimmedText, accessToken: token)
                await MainActor.run {
                    binItems.insert(newItem, at: 0)
                    newItemText = ""
                    isSubmitting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
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
}

struct BinItemRow: View {
    let item: BinItem
    let accessToken: String?
    let onDelete: () -> Void
    
    @State private var isCopied = false
    @State private var isDownloading = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
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
                
                HStack(spacing: 8) {
                    // Copy button
                    Button(action: copyItem) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(isCopied ? .green : AppColors.mutedText(isDarkMode: isDarkMode))
                    }
                    .disabled(isDownloading)
                    
                    // Download button (for files)
                    if item.isFile {
                        Button(action: downloadItem) {
                            Image(systemName: isDownloading ? "checkmark" : "arrow.down.circle")
                                .foregroundColor(isDownloading ? .green : AppColors.mutedText(isDarkMode: isDarkMode))
                        }
                        .disabled(isDownloading)
                    }
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Image preview for image files
            if item.isFile, let fileItem = item.fileItem, fileItem.contentType.hasPrefix("image/") {
                ImagePreviewView(item: item, accessToken: accessToken, isDarkMode: isDarkMode)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                )
        )
        .shadow(
            color: AppColors.cardShadow(isDarkMode: isDarkMode),
            radius: 8,
            x: 0,
            y: 4
        )
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
        } else if item.isFile {
            // TODO: Implement file copying to clipboard
        }
        
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
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
                
                // Save to documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = item.fileItem?.originalName ?? "download"
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                try data.write(to: fileURL)
                
                await MainActor.run {
                    isDownloading = false
                    // Show success feedback
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    // Show error feedback
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
                                .stroke(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
                        )
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
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
                            .stroke(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
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
                            .stroke(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
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
