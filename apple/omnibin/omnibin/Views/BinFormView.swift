import SwiftUI
import PhotosUI

// MARK: - Bin Form View
struct BinFormView: View {
    @Binding var isSubmitting: Bool
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var showTextInputDialog: Bool
    @Binding var errorMessage: String?
    let binItemsCount: Int
    let binItemsLimit: Int
    let isDarkMode: Bool
    let onPasteFromClipboard: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Paste from Clipboard button (full width)
            Button(action: onPasteFromClipboard) {
                HStack(spacing: 12) {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: isIPad ? 27 : 18, weight: .medium))
                    }
                    
                    Text(isSubmitting ? "Pasting..." : "Paste from Clipboard")
                        .font(.system(size: isIPad ? 24 : 16, weight: .semibold))
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
            .frame(height: isIPad ? 78 : 52)
            
            // Text and Photos buttons row
            HStack(spacing: 12) {
                // Add Text button
                Button(action: { showTextInputDialog = true }) {
                    Image(systemName: "textformat")
                        .font(.system(size: isIPad ? 27 : 18, weight: .medium))
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
                .frame(height: isIPad ? 78 : 52)
                
                // Upload from Photos button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: isIPad ? 27 : 18, weight: .medium))
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
                .frame(height: isIPad ? 78 : 52)
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Items: \(min(binItemsCount, binItemsLimit)) / \(binItemsLimit)")
                    .font(isIPad ? .system(size: 23) : .caption)
                    .foregroundColor(binItemsCount >= binItemsLimit ? .red : AppColors.mutedText(isDarkMode: isDarkMode))
                
                if binItemsCount >= binItemsLimit {
                    Text("Oldest item will be deleted on next add.")
                        .font(isIPad ? .system(size: 12) : .caption2)
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            if let error = errorMessage {
                Text(error)
                    .font(isIPad ? .system(size: 15) : .caption)
                    .foregroundColor(.red)
            }
        }
    }
}
