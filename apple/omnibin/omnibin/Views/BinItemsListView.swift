import SwiftUI

// MARK: - Bin Items List View
struct BinItemsListView: View {
    let binItems: [BinItem]
    let isLoading: Bool
    let accessToken: String?
    let isDarkMode: Bool
    let onDeleteItem: (String) -> Void
    let onRestoreItem: (BinItem) -> Void
    
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width
    
    var body: some View {
        Group {
            if isLoading {
                if isTwoColumn {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(spacing: 8) {
                            ForEach(0..<2, id: \.self) { _ in
                                BinItemSkeletonView(isDarkMode: isDarkMode, isTwoColumn: true)
                                    .padding(.horizontal, 1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        VStack(spacing: 8) {
                            ForEach(0..<2, id: \.self) { _ in
                                BinItemSkeletonView(isDarkMode: isDarkMode, isTwoColumn: true)
                                    .padding(.horizontal, 1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { _ in
                            BinItemSkeletonView(isDarkMode: isDarkMode, isTwoColumn: false)
                        }
                    }
                }
            } else if binItems.isEmpty {
                Text("Nothing here yet. Paste something above.")
                    .font(.system(size: isIPad ? 17 : 14))
                    .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else {
                if isTwoColumn {
                    HStack(alignment: .top, spacing: 8) {
                        // First column - even indices
                        VStack(spacing: 8) {
                            ForEach(Array(binItems.enumerated().filter { $0.offset % 2 == 0 }), id: \.element.id) { _, item in
                                BinItemRow(item: item, accessToken: accessToken, onDelete: {
                                    onDeleteItem(item.id)
                                }, onRestore: {
                                    onRestoreItem(item)
                                })
                                .id(item.id)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        // Second column - odd indices
                        VStack(spacing: 8) {
                            ForEach(Array(binItems.enumerated().filter { $0.offset % 2 == 1 }), id: \.element.id) { _, item in
                                BinItemRow(item: item, accessToken: accessToken, onDelete: {
                                    onDeleteItem(item.id)
                                }, onRestore: {
                                    onRestoreItem(item)
                                })
                                .id(item.id)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 8) {
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
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            screenWidth = UIScreen.main.bounds.width
        }
    }
}

// MARK: - Bin Item Skeleton View
struct BinItemSkeletonView: View {
    let isDarkMode: Bool
    let isTwoColumn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: isIPad ? 240 : 200, height: isIPad ? 18 : 14)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                    .frame(width: 14, height: 14)
                    .padding(.trailing, 13)
            }
            .padding(.leading, 14)
            .frame(height: 46)

            Rectangle()
                .fill(AppColors.skeletonColor(isDarkMode: isDarkMode))
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 320 : 180)
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
    }
}
