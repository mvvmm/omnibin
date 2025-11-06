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
                        .onAppear {
                            // Download the image to calculate height
                            downloadImageForCalculation(from: imageURL)
                        }
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
                                .frame(width: isIPad ? 460 : 300, height: isIPad ? 16 : 14)
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
                    self.og = data  // Allow OG data to display
                    self.ogOut = data  // Allow ogOut to be set so metadata can show
                    self.isOGLoading = false  // Ensure loading state is cleared when OG data loads
                }
            }
        } catch {
            // ignore; show nothing if OG fails
            await MainActor.run {
                self.isOGLoading = false  // Clear loading state even on error
            }
        }
    }
    
    private func downloadImageForCalculation(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await setDownloadedImage(image)
                    let width = await getContainerWidth()
                    let height = getIdealImageHeight(for: image, containerWidth: width)
                    await MainActor.run {
                        calculatedHeight = height
                    }
                }
            } catch {
                // Silently fail for image download
            }
        }
    }
    
    @MainActor
    private func getContainerWidth() -> CGFloat? {
        return containerWidth
    }
    
    @MainActor
    private func setDownloadedImage(_ image: UIImage) async {
        downloadedImage = image
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
