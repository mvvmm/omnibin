import SwiftUI

// MARK: - Bin Items List View
struct BinItemsListView: View {
    let binItems: [BinItem]
    let isLoading: Bool
    let accessToken: String?
    let isDarkMode: Bool
    let onDeleteItem: (String) -> Void
    let onRestoreItem: (BinItem) -> Void

    @State private var availableWidth: CGFloat = 0

    // Lay out by the space the window actually has, not the device type, so iPad split view,
    // Stage Manager and iPhone Duo's inner display all get the right column count.
    private static let twoColumnMinWidth: CGFloat = 560
    private static let columnSpacing: CGFloat = 12

    private var columnCount: Int {
        availableWidth >= Self.twoColumnMinWidth ? 2 : 1
    }

    private var columnWidth: CGFloat {
        guard columnCount == 2 else { return availableWidth }
        return (availableWidth - Self.columnSpacing) / 2
    }

    var body: some View {
        Group {
            if isLoading {
                columns(Array(0..<(columnCount * 2)), id: \.self) { _ in
                    BinItemSkeletonView(isDarkMode: isDarkMode)
                }
            } else if binItems.isEmpty {
                Text("Nothing here yet. Paste something above.")
                    .font(.system(size: isIPad ? 17 : 14))
                    .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 48)
            } else {
                columns(binItems, id: \.id) { item in
                    BinItemRow(item: item, accessToken: accessToken, columnWidth: columnWidth, onDelete: {
                        onDeleteItem(item.id)
                    }, onRestore: {
                        onRestoreItem(item)
                    })
                    .id(item.id)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
    }

    private func columns<Element, ID: Hashable, Content: View>(
        _ elements: [Element],
        id: KeyPath<Element, ID>,
        @ViewBuilder content: @escaping (Element) -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: Self.columnSpacing) {
            ForEach(0..<columnCount, id: \.self) { column in
                VStack(spacing: 8) {
                    ForEach(elements.enumerated().filter { $0.offset % columnCount == column }.map(\.element), id: id) { element in
                        content(element)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
}

// MARK: - Bin Item Skeleton View
struct BinItemSkeletonView: View {
    let isDarkMode: Bool

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

#Preview {
    let now = "2026-10-18T09:00:00.000Z"
    func text(_ id: String, _ content: String, ogTitle: String? = nil) -> BinItem {
        BinItem(
            id: id, userId: "preview", kind: "TEXT",
            textItem: TextItem(
                id: id, content: content, ogDataFetched: true, ogTitle: ogTitle, ogDescription: nil,
                ogImage: nil, ogImageWidth: nil, ogImageHeight: nil, ogIcon: nil, ogSiteName: nil,
                createdAt: now, updatedAt: now
            ),
            fileItem: nil, createdAt: now, updatedAt: now
        )
    }
    let pdf = BinItem(
        id: "pdf", userId: "preview", kind: "FILE", textItem: nil,
        fileItem: FileItem(
            id: "pdf", provider: "r2", bucket: "preview", key: "invoice.pdf", originalName: "invoice.pdf",
            contentType: "application/pdf", size: "73000", checksum: nil, preview: nil,
            imageWidth: nil, imageHeight: nil, expiresAt: nil, createdAt: now, updatedAt: now
        ),
        createdAt: now, updatedAt: now
    )
    let items = [
        text("alice", "“Who in the world am I?” Ah, that’s the great puzzle, said Alice as she wandered deeper into the wood"),
        text("link", "https://www.youtube.com/watch?v=2SuvO4Gi7uY", ogTitle: "Coding Challenge 186: Wave Function Collapse"),
        pdf,
        text("ssh", "ssh deploy@10.0.4.12 -p 2222"),
        text("todo", "Pick up dry cleaning before 6\nCall back re: dentist on Thursday"),
        text("gh", "https://github.com/withastro/astro/releases", ogTitle: "Releases · withastro/astro"),
    ]
    return ScrollView {
        BinItemsListView(
            binItems: items, isLoading: false, accessToken: nil, isDarkMode: true,
            onDeleteItem: { _ in }, onRestoreItem: { _ in }
        )
        .padding(16)
    }
    .background(AppColors.background(isDarkMode: true))
    .preferredColorScheme(.dark)
}
