import SwiftUI
import UIKit

// MARK: - URL Preview View (Open Graph)
struct URLPreviewView: View {
    let text: String
    let accessToken: String?
    let isDarkMode: Bool
    @Binding var ogOut: OGData?
    @Binding var isOGLoading: Bool

    @State private var og: OGData?
    @State private var isLoading = false
    @State private var calculatedHeight: CGFloat = defaultImageHeight
    @State private var downloadedImage: UIImage?
    @State private var containerWidth: CGFloat?
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width

    var body: some View {
        Group {
            if let urlString = extractFirstURL(from: text), let url = URL(string: urlString) {
                // If we have OG, render image + text; otherwise render compact text card
                if let og = og {
                // Determine a valid image URL if provided
                let trimmedImage = og.image?.trimmingCharacters(in: .whitespacesAndNewlines)
                let imageURL = (trimmedImage?.isEmpty == false) ? URL(string: trimmedImage!) : nil
                
                VStack(alignment: .leading, spacing: 0) {
                    if let imageURL = imageURL {
                        GeometryReader { geometry in
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: calculatedHeight)
                                    .clipped()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode).opacity(0.5))
                                    .frame(width: geometry.size.width)
                                    .frame(height: calculatedHeight)
                            }
                            .onAppear {
                                if containerWidth == nil {
                                    containerWidth = geometry.size.width
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: calculatedHeight)
                        .clipped()
                        .contentShape(Rectangle())
                    }
                    // Title/description row. Only show favicon when there is no image and icon URL exists
                    HStack(alignment: .center, spacing: 10) {
                        if imageURL == nil, let iconURL = faviconURL(for: url, og: og) {
                            AsyncImage(url: iconURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(4)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode).opacity(0.5))
                                    .frame(width: 20, height: 20)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                        Text((og.title?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? (url.host ?? url.absoluteString))
                            .font(isIPad ? .system(size: 21, weight: .semibold) : .headline)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                            .lineLimit(2)
                        Text(url.absoluteString)
                            .font(isIPad ? .system(size: 15) : .caption)
                            .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                            .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, imageURL != nil ? 12 : 16)
                    .padding(.bottom, 16)
                }
                .overlay(
                    // Add top and bottom borders when there's no image
                    Group {
                        if imageURL == nil {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(AppColors.featureCardBorder(isDarkMode: isDarkMode))
                                    .frame(height: 1)
                                Spacer()
                                Rectangle()
                                    .fill(AppColors.featureCardBorder(isDarkMode: isDarkMode))
                                    .frame(height: 1)
                            }
                        }
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.open(url)
                }
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = url.absoluteString
                    }) {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: {
                        UIApplication.shared.open(url)
                    }) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                    
                    Button(action: {
                        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                        if let topViewController = topMostViewController() {
                            // Configure for iPad
                            if let popover = activityVC.popoverPresentationController {
                                popover.sourceView = topViewController.view
                                popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
                                popover.permittedArrowDirections = []
                            }
                            topViewController.present(activityVC, animated: true)
                        }
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                } else if isLoading || isOGLoading {
                    // Skeleton loading state - matching BinItemsListView skeleton
                    VStack(alignment: .leading, spacing: 0) {
                        // Image skeleton
                        RoundedRectangle(cornerRadius: 0)
                            .fill(AppColors.skeletonColor(isDarkMode: isDarkMode).opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .frame(height: calculatedHeight)
                            .padding(.bottom, 0)
                        
                        // URL preview text section - matching BinItemsListView structure
                        VStack(alignment: .leading, spacing: 0) {
                            // Title skeleton
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                                .frame(width: isIPad ? 336 : 260, height: isIPad ? 20 : 18)

                            // site url skeleton - slightly shorter than title
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                                .frame(width: isIPad && !isTwoColumn ? 460 : 300, height: isIPad ? 16 : 14)
                                .padding(.top, 6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 0) // Match "has image" case - BinItemRow will add padding when urlOG?.image is nil
                    }
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
                                EmptyView()
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(url.host ?? url.absoluteString)
                                .font(isIPad ? .system(size: 21, weight: .semibold) : .headline)
                                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                .lineLimit(1)
                            Text(url.absoluteString)
                                .font(isIPad ? .system(size: 15) : .caption)
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
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { UIApplication.shared.open(url) }
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = url.absoluteString
                        }) {
                            Label("Copy URL", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Label("Open in Browser", systemImage: "safari")
                        }
                        
                        Button(action: {
                            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            if let topViewController = topMostViewController() {
                                // Configure for iPad
                                if let popover = activityVC.popoverPresentationController {
                                    popover.sourceView = topViewController.view
                                    popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
                                    popover.permittedArrowDirections = []
                                }
                                topViewController.present(activityVC, animated: true)
                            }
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .onAppear { 
            // Set loading state immediately if URL is detected
            if extractFirstURL(from: text) != nil {
                isOGLoading = true
            }
            Task { await loadOGIfNeeded() } 
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // Update screen width and recalculate height when orientation changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                screenWidth = UIScreen.main.bounds.width
                if let ogData = og {
                    calculateHeightFromOGDimensions(ogData)
                }
            }
        }
    }

    private func extractFirstURL(from text: String) -> String? {
        let types: NSTextCheckingResult.CheckingType = .link
        let detector = try? NSDataDetector(types: types.rawValue)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let match = detector?.firstMatch(in: text, options: [], range: range)
        if let r = match?.range, let swiftRange = Range(r, in: text) {
            let raw = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return normalizeURLString(raw)
        }
        return nil
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

    private func loadOGIfNeeded() async {
        guard let token = accessToken, !token.isEmpty else { return }
        guard let url = extractFirstURL(from: text) else { return }
        
        // Set loading state immediately
        await MainActor.run { 
            self.isLoading = true
            self.isOGLoading = true
        }
        
        defer { 
            Task { @MainActor in
                self.isLoading = false
                self.isOGLoading = false
            }
        }
        
        do {
            if let data = try await BinAPI.shared.fetchOpenGraph(url: url, accessToken: token) {
                await MainActor.run { 
                    self.og = data  // Set OG data
                    self.ogOut = data  // Allow ogOut to be set so metadata can show
                    
                    // Calculate height from OG dimensions if available
                    self.calculateHeightFromOGDimensions(data)
                    
                    self.isOGLoading = false  // Ensure loading state is cleared when OG data loads
                }
                
                // Download image in background for display
                let trimmedImage = data.image?.trimmingCharacters(in: .whitespacesAndNewlines)
                if let imageURLString = trimmedImage, !imageURLString.isEmpty, let imageURL = URL(string: imageURLString) {
                    await downloadImageForDisplay(from: imageURL)
                }
            }
        } catch {
            // ignore; show nothing if OG fails
            await MainActor.run {
                self.isOGLoading = false  // Clear loading state even on error
            }
        }
    }
    
    private func calculateHeightFromOGDimensions(_ ogData: OGData) {
        // Use provided dimensions or default OG image size (1200x630)
        let imageWidth = ogData.imageWidth ?? 1200
        let imageHeight = ogData.imageHeight ?? 630
        
        guard imageWidth > 0, imageHeight > 0 else {
            return
        }
        
        // Calculate available width accounting for two-column layout
        let basePadding: CGFloat = 32 // Horizontal padding
        
        // Check if two-column layout based on current screen width
        let shouldUseTwoColumn = isIPad && screenWidth >= 900
        
        let availableWidth: CGFloat
        if shouldUseTwoColumn {
            // In two-column mode: divide width by 2 and account for spacing between columns
            let columnSpacing: CGFloat = 12
            availableWidth = (screenWidth - basePadding - columnSpacing) / 2
        } else {
            // Single column mode
            availableWidth = screenWidth - basePadding
        }
        
        let aspectRatio = CGFloat(imageHeight) / CGFloat(imageWidth)
        let desiredHeight = availableWidth * aspectRatio
        
        // Clamp to maximum height first
        var finalHeight = min(desiredHeight, maxIdealImageHeight)
        
        // Only apply minimum height if it won't cause the image to exceed available width
        // Calculate what width would be needed for the minimum height
        let widthNeededForMinHeight = minIdealImageHeight / aspectRatio
        
        if finalHeight < minIdealImageHeight && widthNeededForMinHeight <= availableWidth {
            // Safe to use minimum height - image won't be clipped horizontally
            finalHeight = minIdealImageHeight
        }
        // Otherwise, use the calculated height to ensure image fits width properly
        
        calculatedHeight = finalHeight
    }
    
    private func downloadImageForDisplay(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    downloadedImage = image
                }
            }
        } catch {
            // Silently fail for image download
        }
    }
    
    // MARK: - Helper to find topmost view controller
    @MainActor
    private func topMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
    }
}
