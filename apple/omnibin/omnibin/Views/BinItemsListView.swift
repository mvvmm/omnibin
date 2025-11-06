import SwiftUI

// MARK: - Bin Items List View
struct BinItemsListView: View {
    let binItems: [BinItem]
    let isLoading: Bool
    let accessToken: String?
    let isDarkMode: Bool
    let onDeleteItem: (String) -> Void
    let onRestoreItem: (BinItem) -> Void
    
    var body: some View {
        if isLoading {
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    BinItemSkeletonView(isDarkMode: isDarkMode)
                }
            }
        } else if binItems.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: isIPad ? 72 : 48))
                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                
                Text("No items yet")
                    .font(isIPad ? .system(size: 21, weight: .semibold) : .headline)
                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                
                Text("Paste text or files to get started")
                    .font(isIPad ? .system(size: 18) : .subheadline)
                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
            }
            .padding(.top, 60)
        } else {
            VStack(spacing: 12) {
                ForEach(binItems, id: \.id) { item in
                    BinItemRow(item: item, accessToken: accessToken, onDelete: {
                        onDeleteItem(item.id)
                    }, onRestore: {
                        onRestoreItem(item)
                    })
                    .id(item.id)
                }
            }
        }
    }
}

// MARK: - Bin Item Skeleton View
struct BinItemSkeletonView: View {
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            HStack {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: isIPad ? 240 : 280, height: isIPad ? 24 : 20)
                
                Spacer()
                
                // Chevron button skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: isIPad ? 24 : 14, height: isIPad ? 24 : 14)
            }
            .padding(16)
            .padding(.bottom, 8)
            
            // Image/preview skeleton - matching actual item height
            RoundedRectangle(cornerRadius: 0)
                .fill(AppColors.skeletonColor(isDarkMode: isDarkMode).opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 350 : 200)
                .padding(.bottom, 0)
            
            // URL preview text section - matching URLPreviewView structure
            VStack(alignment: .leading, spacing: 0) {
                // Title skeleton - matching top title width
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: isIPad ? 336 : 260, height: isIPad ? 20 : 18)
                
                // site url skeleton - slightly shorter than title
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: isIPad ? 460 : 300, height: isIPad ? 16 : 14)
                    .padding(.top, 6)
                
                // metadata skeleton - much wider, with extra space above
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: isIPad ? 280 : 120, height: isIPad ? 14 : 12)
                    .padding(.top, 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 0)
        }
        .padding(.bottom, 16)
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
        .overlay(
            // Simple shimmer overlay
            ShimmerOverlay()
                .blendMode(.overlay)
        )
    }
    
}

// MARK: - Shimmer Overlay
struct ShimmerOverlay: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.3),
                    .init(color: Color.white.opacity(0.3), location: 0.5),
                    .init(color: .clear, location: 0.7),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: geometry.size.width * 2)
            .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
        }
        .onAppear {
            phase = 0
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

