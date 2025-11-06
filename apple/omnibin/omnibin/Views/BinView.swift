import SwiftUI
import PhotosUI

// MARK: - Bin View
struct BinView: View {
    let accessToken: String?
    let onLogout: () -> Void
    let authService: MainViewAuthService
    
    @StateObject private var viewModel: BinViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDeleteAccountAlert = false
    @State private var isDeletingAccount = false
    @State private var showPastePermissionPopup = false
    
    init(accessToken: String?, onLogout: @escaping () -> Void, authService: MainViewAuthService) {
        self.accessToken = accessToken
        self.onLogout = onLogout
        self.authService = authService
        self._viewModel = StateObject(wrappedValue: BinViewModel(accessToken: accessToken))
    }
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    // MARK: - Account Deletion
    
    private func deleteAccount() async {
        guard let accessToken = accessToken else {
            print("❌ No access token available for account deletion")
            return
        }
        
        isDeletingAccount = true
        
        do {
            let success = try await AccountDeletionService.shared.deleteAccount(accessToken: accessToken)
            if success {
                print("✅ Account successfully deleted")
                // Clear session locally without triggering Auth0 logout popup
                await MainActor.run {
                    authService.clearSessionLocally()
                }
            } else {
                print("❌ Account deletion failed")
            }
        } catch {
            print("❌ Account deletion error: \(error.localizedDescription)")
        }
        
        isDeletingAccount = false
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    BinHeaderView(
                        onLogout: onLogout,
                        onDeleteAccount: {
                            showDeleteAccountAlert = true
                        },
                        isDarkMode: isDarkMode
                    )
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    .padding(.horizontal, min(24, geometry.size.width * 0.05))
                    
                    // Content
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
                            onPasteFromClipboard: {
                                viewModel.pasteFromClipboard {
                                    // Show settings popup after successful paste (if it hasn't been shown before)
                                    if PastePermissionManager.shared.shouldShowPopup() {
                                        showPastePermissionPopup = true
                                    }
                                }
                            }
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
            .refreshable {
                await viewModel.refreshBinItems()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.loadBinItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
            Task {
                await viewModel.refreshBinItems()
            }
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {
                showDeleteAccountAlert = false
            }
            Button("Delete Account", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data, including:\n\n• All your bin items (text, images, files, etc.)\n• All uploaded files from storage\n• Your account and authentication data")
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
        .sheet(isPresented: $showPastePermissionPopup) {
            PastePermissionPopupView(
                onDismiss: {
                    showPastePermissionPopup = false
                    PastePermissionManager.shared.markPopupAsShown()
                },
                onOpenSettings: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                    showPastePermissionPopup = false
                    PastePermissionManager.shared.markPopupAsShown()
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    BinView(accessToken: nil, onLogout: {}, authService: MainViewAuthService())
}
