import SwiftUI
import UIKit

// MARK: - URL Preview View (Open Graph)
struct URLPreviewView: View {
    let text: String
    let accessToken: String?
    let isDarkMode: Bool
    let availableWidth: CGFloat
    let ogData: OGData? // OG data from API
    let ogDataFetched: Bool // Whether OG data has been fetched
    @Binding var ogOut: OGData?
    @Binding var isOGLoading: Bool

    @State private var og: OGData?
    @State private var isLoading = false
    @State private var calculatedHeight: CGFloat = defaultImageHeight
    @State private var downloadedImage: UIImage?

    var body: some View {
        Group {
            if let urlString = extractFirstURL(from: text), let url = URL(string: urlString) {
                // Determine a valid image URL if OG data provided
                // Upgrade http to https — iOS ATS blocks plain http, causing AsyncImage to silently fail
                let trimmedImage = og?.image?.trimmingCharacters(in: .whitespacesAndNewlines)
                let httpsImage = trimmedImage?.hasPrefix("http://") == true
                    ? "https://" + trimmedImage!.dropFirst("http://".count)
                    : trimmedImage
                let imageURL = (httpsImage?.isEmpty == false) ? URL(string: httpsImage!) : nil
                
                if isLoading || isOGLoading {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity)
                        .frame(height: calculatedHeight)
                } else {
                    Group {
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
                                        .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                                        .frame(width: geometry.size.width)
                                        .frame(height: calculatedHeight)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: calculatedHeight)
                            .clipped()
                        } else {
                            // Keeps a view in the tree so onAppear still clears isOGLoading
                            Color.clear.frame(height: 0)
                        }
                    }
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
                }
            }
        }
        .onAppear { 
            // Use provided OG data from API instead of fetching
            if let providedOgData = ogData {
                self.og = providedOgData
                self.ogOut = providedOgData
                self.isOGLoading = false
                self.calculateHeightFromOGDimensions(providedOgData)
            } else if ogDataFetched {
                // OG data was fetched but no data available
                self.isOGLoading = false
            } else {
                // OG data not yet fetched (shouldn't happen with new architecture)
                self.isOGLoading = false
            }
        }
        .onChange(of: availableWidth) {
            if let ogData = og {
                calculateHeightFromOGDimensions(ogData)
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

    private func calculateHeightFromOGDimensions(_ ogData: OGData) {
        // Use provided dimensions or default OG image size (1200x630)
        let imageWidth = ogData.imageWidth ?? 1200
        let imageHeight = ogData.imageHeight ?? 630
        
        guard imageWidth > 0, imageHeight > 0 else {
            return
        }
        
        guard availableWidth > 0 else { return }
        
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
