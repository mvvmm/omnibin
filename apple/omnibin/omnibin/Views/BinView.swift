import SwiftUI
import PhotosUI

// MARK: - Bin View
struct BinView: View {
    let accessToken: String?
    let onLogout: () -> Void
    
    @StateObject private var viewModel: BinViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    init(accessToken: String?, onLogout: @escaping () -> Void) {
        self.accessToken = accessToken
        self.onLogout = onLogout
        self._viewModel = StateObject(wrappedValue: BinViewModel(accessToken: accessToken))
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                BinHeaderView(onLogout: onLogout, isDarkMode: isDarkMode)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .padding(.horizontal, min(24, geometry.size.width * 0.05))
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Add new item form
                        BinFormView(
                            isSubmitting: $viewModel.isSubmitting,
                            selectedPhoto: $viewModel.selectedPhoto,
                            showTextInputDialog: $viewModel.showTextInputDialog,
                            errorMessage: $viewModel.errorMessage,
                            binItemsCount: viewModel.binItems.count,
                            binItemsLimit: viewModel.binItemsLimit,
                            isDarkMode: isDarkMode,
                            onPasteFromClipboard: viewModel.pasteFromClipboard
                        )
                        
                        // Items list
                        BinItemsListView(
                            binItems: viewModel.binItems,
                            isLoading: viewModel.isLoading,
                            accessToken: accessToken,
                            isDarkMode: isDarkMode,
                            onDeleteItem: viewModel.deleteItemById,
                            onRestoreItem: viewModel.restoreItem,
                        )
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .padding(.horizontal, min(24, geometry.size.width * 0.05))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .refreshable {
            await viewModel.refreshBinItems()
        }
        .onAppear {
            viewModel.loadBinItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
            Task {
                await viewModel.refreshBinItems()
            }
        }
        .onChange(of: viewModel.selectedPhoto) { _, newPhoto in
            if let newPhoto = newPhoto {
                Task {
                    await viewModel.loadPhoto(newPhoto)
                }
            }
        }
        .alert("Add Text Item", isPresented: $viewModel.showTextInputDialog) {
            TextField("Enter text...", text: $viewModel.textInput, axis: .vertical)
                .lineLimit(5...10)
            Button("Cancel", role: .cancel) {
                viewModel.textInput = ""
            }
            Button("Add") {
                viewModel.addTextFromInput()
            }
            .disabled(viewModel.textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter the text you want to add to your bin.")
        }
    }
}

#Preview {
    BinView(accessToken: nil, onLogout: {})
}
