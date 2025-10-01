import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

struct BinView: View {
    let accessToken: String?
    let onLogout: () -> Void
    
    @State var binItems: [BinItem] = []
    @State var deletedItems: [BinItem] = [] // Store deleted items for potential restoration
    @State var isLoading = false
    @State var errorMessage: String?
    @State var isSubmitting = false
    @State var selectedPhoto: PhotosPickerItem?
    @State var snackbarMessage: String?
    @State var snackbarType: MessageType?
    @State var showTextInputDialog = false
    @State var textInput = ""
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    let maxCharLimit = 10000
    let binItemsLimit = 10
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Your Bin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            onLogout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.Button.accentPrimary)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                .padding(.horizontal, min(24, geometry.size.width * 0.05))
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Add new item form
                        VStack(spacing: 12) {
                            // Paste from Clipboard button (full width)
                            Button(action: pasteFromClipboard) {
                                HStack(spacing: 12) {
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "doc.on.clipboard")
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                    
                                    Text(isSubmitting ? "Pasting..." : "Paste from Clipboard")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    AppColors.Button.accentPrimary,
                                                    AppColors.Button.accentSecondary
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(
                                            color: AppColors.Button.accentPrimary.opacity(0.3),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                                .scaleEffect(isSubmitting ? 0.95 : 1.0)
                                .animation(.easeInOut(duration: 0.1), value: isSubmitting)
                            }
                            .disabled(isSubmitting)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            
                            // Text and Photos buttons row
                            HStack(spacing: 12) {
                                // Add Text button
                                Button(action: { showTextInputDialog = true }) {
                                    Image(systemName: "textformat")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                                                )
                                                .shadow(
                                                    color: AppColors.cardShadow(isDarkMode: isDarkMode),
                                                    radius: 4,
                                                    x: 0,
                                                    y: 2
                                                )
                                        )
                                }
                                .disabled(isSubmitting)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                
                                // Upload from Photos button
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .strokeBorder(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                                                )
                                                .shadow(
                                                    color: AppColors.cardShadow(isDarkMode: isDarkMode),
                                                    radius: 4,
                                                    x: 0,
                                                    y: 2
                                                )
                                        )
                                }
                                .disabled(isSubmitting)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                            }
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Items: \(binItems.count) / \(binItemsLimit)")
                                    .font(.caption)
                                    .foregroundColor(binItems.count >= binItemsLimit ? .red : AppColors.mutedText(isDarkMode: isDarkMode))
                                
                                if binItems.count >= binItemsLimit {
                                    Text("Oldest item will be deleted on next add.")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Items list
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.Button.accentPrimary))
                                
                                Text("Loading your bin...")
                                    .font(.headline)
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                            }
                            .padding(.top, 60)
                        } else if binItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                                
                                Text("No items yet")
                                    .font(.headline)
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                                
                                Text("Paste text or files to get started")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                            }
                            .padding(.top, 60)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(binItems, id: \.id) { item in
                                    BinItemRow(item: item, accessToken: accessToken, onDelete: {
                                        deleteItemById(item.id)
                                    }, onRestore: {
                                        restoreItem(item)
                                    }, onShowMessage: { message, type in
                                        showSnackbar(message: message, type: type)
                                    })
                                    .id(item.id)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .padding(.horizontal, min(24, geometry.size.width * 0.05))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .refreshable {
            await refreshBinItems()
        }
        .onAppear {
            loadBinItems()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
            // Refresh bin items when app becomes active
            Task {
                await refreshBinItems()
            }
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let newPhoto = newPhoto {
                Task {
                    await loadPhoto(newPhoto)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let snackbarMessage = snackbarMessage, let snackbarType = snackbarType {
                SnackbarView(message: snackbarMessage, type: snackbarType) {
                    self.snackbarMessage = nil
                    self.snackbarType = nil
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: snackbarMessage)
            }
        }
        .alert("Add Text Item", isPresented: $showTextInputDialog) {
            TextField("Enter text...", text: $textInput, axis: .vertical)
                .lineLimit(5...10)
            Button("Cancel", role: .cancel) {
                textInput = ""
            }
            Button("Add") {
                addTextFromInput()
            }
            .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter the text you want to add to your bin.")
        }
    }
    
 
}

 


// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}



#Preview {
    BinView(accessToken: nil, onLogout: {})
}

 
