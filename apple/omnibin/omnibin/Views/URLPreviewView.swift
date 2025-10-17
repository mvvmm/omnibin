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
    @State private var isImageLoading = false

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
                        let w = CGFloat(og.imageWidth ?? 16)
                        let h = CGFloat(og.imageHeight ?? 9)
                        ZStack {
                            AsyncImage(url: imageURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                                    .onAppear {
                                        isImageLoading = false
                                    }
                            } placeholder: {
                                Rectangle()
                                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                                    .onAppear {
                                        isImageLoading = true
                                    }
                            }
                            
                            // Show loading skeleton while image is loading
                            if isImageLoading {
                                Rectangle()
                                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                            }
                        }
                        // Size the container purely by its aspect ratio to avoid any extra blank space
                        .aspectRatio(CGSize(width: w, height: h), contentMode: .fit)
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
                                EmptyView()
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                        Text((og.title?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? (url.host ?? url.absoluteString))
                            .font(isIPad ? .system(size: 21, weight: .semibold) : .headline)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                            .lineLimit(2)
                        if let desc = og.description?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
                            Text(desc)
                                .font(isIPad ? .system(size: 18) : .subheadline)
                                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                                .lineLimit(3)
                        }
                        Text((og.siteName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? (url.host ?? ""))
                            .font(isIPad ? .system(size: 15) : .caption)
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
                // Make only the visible card area tappable
                .contentShape(RoundedRectangle(cornerRadius: 8))
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
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(activityVC, animated: true)
                        }
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
                } else if isLoading || isOGLoading {
                    // Skeleton loading state
                    VStack(alignment: .leading, spacing: 0) {
                        // Image skeleton
                        Rectangle()
                            .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3), lineWidth: 1)
                            )
                        
                        // Content skeleton
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 6) {
                                // Title skeleton
                                Rectangle()
                                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                                    .frame(height: 16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Description skeleton
                                Rectangle()
                                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                                    .frame(height: 14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Site name skeleton
                                Rectangle()
                                    .fill(AppColors.mutedText(isDarkMode: isDarkMode).opacity(0.3))
                                    .frame(width: 80, height: 12)
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
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                window.rootViewController?.present(activityVC, animated: true)
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
                    self.og = data
                    self.ogOut = data
                }
            }
        } catch {
            // ignore; show nothing if OG fails
        }
    }
}
