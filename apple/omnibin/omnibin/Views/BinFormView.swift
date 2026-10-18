import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Bin Form View
struct BinFormView: View {
    @Binding var isSubmitting: Bool
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var showTextInputDialog: Bool
    @Binding var showFileImporter: Bool
    @Binding var errorMessage: String?
    let binItemsCount: Int
    let binItemsLimit: Int
    let isDarkMode: Bool
    let onPasteFromClipboard: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onPasteFromClipboard) {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .tint(AppColors.onAccent)
                    } else {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    }
                    Text(isSubmitting ? "Pasting…" : "Paste from clipboard")
                        .font(.system(size: isIPad ? 20 : 16, weight: .semibold))
                }
                .foregroundColor(AppColors.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 64 : 52)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.accent)
                )
                .opacity(isSubmitting ? 0.7 : 1)
            }
            .buttonStyle(.plain)
            .disabled(isSubmitting)

            HStack(spacing: 0) {
                sourceButton("Text", systemImage: "textformat") {
                    showTextInputDialog = true
                }
                divider
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    sourceLabel("Photos", systemImage: "photo")
                }
                .disabled(isSubmitting)
                divider
                sourceButton("Files", systemImage: "folder") {
                    showFileImporter = true
                }
            }
            .frame(height: isIPad ? 60 : 48)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.surface(isDarkMode: isDarkMode))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(AppColors.border(isDarkMode: isDarkMode), lineWidth: 1)
            )

            HStack(alignment: .top) {
                Group {
                    if let error = errorMessage {
                        Text(error)
                    } else if binItemsCount >= binItemsLimit {
                        Text("Oldest item will be deleted on next add.")
                    }
                }
                .font(.system(size: isIPad ? 15 : 12))
                .foregroundColor(AppColors.danger(isDarkMode: isDarkMode))

                Spacer()

                Text("\(min(binItemsCount, binItemsLimit)) / \(binItemsLimit)")
                    .font(.system(size: isIPad ? 14 : 11, design: .monospaced))
                    .foregroundColor(
                        binItemsCount >= binItemsLimit
                            ? AppColors.danger(isDarkMode: isDarkMode)
                            : AppColors.mutedText(isDarkMode: isDarkMode)
                    )
            }
            .padding(.horizontal, 2)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(AppColors.border(isDarkMode: isDarkMode))
            .frame(width: 1)
    }

    private func sourceButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            sourceLabel(title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }

    private func sourceLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: isIPad ? 18 : 15, weight: .medium))
                .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
            Text(title)
                .font(.system(size: isIPad ? 17 : 14, weight: .medium))
                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
