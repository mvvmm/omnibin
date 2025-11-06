import SwiftUI
import UIKit

struct ImagePreviewView: View {
    let item: BinItem
    let accessToken: String?
    let isDarkMode: Bool
    
    @State private var imageURL: String?
    @State private var hasError = false
    @State private var downloadedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let imageURL = imageURL, let url = URL(string: imageURL) {
                    GeometryReader { geometry in
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: isIPad ? 350 : 200)
                                .clipped()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(AppColors.skeletonColor(isDarkMode: isDarkMode).opacity(0.5))
                                .frame(width: geometry.size.width, height: isIPad ? 350 : 200)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 350 : 200)
                    .clipped()
                    .padding(.horizontal, 1) // Add 1px padding on sides to ensure image sits inside border
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
                    .onAppear {
                        // Download the image for context menu actions
                        downloadImageForContextMenu(from: url)
                    }
                } else if hasError {
                    Rectangle()
                        .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 350 : 200)
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
                }
            }
        }
        .onAppear {
            loadImageURL()
        }
    }
    
    private func loadImageURL() {
        guard let token = accessToken else {
            hasError = true
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
