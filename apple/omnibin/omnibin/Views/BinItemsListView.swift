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
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.Button.accentPrimary))
                
                Text("Loading your bin...")
                    .font(isIPad ? .system(size: 21, weight: .semibold) : .headline)
                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
            }
            .padding(.top, 60)
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
