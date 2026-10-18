import SwiftUI

// MARK: - Paste Permission Popup View
struct PastePermissionPopupView: View {
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Allow paste from other apps")
                            .font(.system(size: isIPad ? 28 : 24, weight: .semibold))
                            .tracking(-0.4)
                            .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))

                        Text("So iOS stops asking every time you paste into omnibin, set \"Paste from Other Apps\" to Allow in Settings.")
                            .font(.system(size: isIPad ? 18 : 15))
                            .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                    }
                    .padding(.top, 16)

                    Image("always-allow-paste-setting")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppColors.border(isDarkMode: isDarkMode), lineWidth: 1)
                        )
                        .accessibilityLabel("The Paste from Other Apps setting set to Allow")

                    Text("You can change this later from the settings menu in omnibin.")
                        .font(.system(size: isIPad ? 16 : 13))
                        .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)

            VStack(spacing: 8) {
                Button(action: onOpenSettings) {
                    Text("Open Settings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.onAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.accent)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text("Not now")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(AppColors.strongBorder(isDarkMode: isDarkMode), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: isIPad ? 600 : .infinity)
        .background(AppColors.surface(isDarkMode: isDarkMode).ignoresSafeArea())
    }
}

#Preview {
    PastePermissionPopupView(
        onDismiss: {},
        onOpenSettings: {}
    )
}
