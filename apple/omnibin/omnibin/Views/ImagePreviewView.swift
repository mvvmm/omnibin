import SwiftUI
import UIKit

struct ImagePreviewView: View {
    let item: BinItem
    let accessToken: String?
    let isDarkMode: Bool
    
    @State private var imageURL: String?
    @State private var hasError = false
    @State private var downloadedImage: UIImage?
    @State private var calculatedHeight: CGFloat = defaultImageHeight
    @State private var containerWidth: CGFloat?
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let imageURL = imageURL, let url = URL(string: imageURL) {
                    GeometryReader { geometry in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: calculatedHeight)
                                .clipped()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(AppColors.skeletonColor(isDarkMode: isDarkMode).opacity(0.5))
                                .frame(width: geometry.size.width, height: calculatedHeight)
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
                                    if let topViewController = topMostViewController() {
                                        // Configure for iPad
                                        if let popover = activityVC.popoverPresentationController {
                                            popover.sourceView = topViewController.view
                                            popover.sourceRect = CGRect(x: topViewController.view.bounds.midX, y: topViewController.view.bounds.midY, width: 0, height: 0)
                                            popover.permittedArrowDirections = []
                                        }
                                        topViewController.present(activityVC, animated: true)
                                    }
                                }
                            }) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                } else if hasError {
                    Rectangle()
                        .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: calculatedHeight)
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
                    RoundedRectangle(cornerRadius: 0)
                        .fill(AppColors.skeletonColor(isDarkMode: isDarkMode).opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .frame(height: calculatedHeight)
                }
            }
        }
        .onAppear {
            // Calculate height from database dimensions immediately
            calculateHeightFromDimensions()
            loadImageURL()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // Update screen width and recalculate height when orientation changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                screenWidth = UIScreen.main.bounds.width
                calculateHeightFromDimensions()
            }
        }
    }
    
    private func calculateHeightFromDimensions() {
        guard let fileItem = item.fileItem,
              let imageWidth = fileItem.imageWidth,
              let imageHeight = fileItem.imageHeight,
              imageWidth > 0,
              imageHeight > 0 else {
            // No dimensions available, use default
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
    
    private func loadImageURL() {
        guard let token = accessToken else {
            hasError = true
            return
        }
        
        Task {
            do {
                let urlString = try await BinAPI.shared.getFileDownloadURL(itemId: item.id, accessToken: token)
                await setImageURLLoaded(urlString)
                
                // Download image in background for context menu
                if let url = URL(string: urlString) {
                    await downloadImageForContextMenu(from: url)
                }
            } catch {
                await setImageURLError()
            }
        }
    }
    
    private func downloadImageForContextMenu(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await setDownloadedImage(image)
            }
        } catch {
            // Silently fail for context menu image download
        }
    }

    // MARK: - ImagePreviewView MainActor helpers
    @MainActor
    private func setImageURLLoaded(_ url: String) async {
        imageURL = url
    }

    @MainActor
    private func setImageURLError() async {
        hasError = true
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
