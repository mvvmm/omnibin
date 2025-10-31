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
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Title
                    Text("Always Allow Paste from Other Apps")
                        .font(.system(size: isIPad ? 28 : 22, weight: .bold))
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    // Message
                    VStack(alignment: .leading, spacing: 12) {
                        Text("To paste content from other apps into omnibin without asking for permission every time, always allow 'Paste from Other Apps' in Settings.")
                            .font(.system(size: isIPad ? 20 : 16))
                            .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                    }
                    .padding(.horizontal, 4)
                    
                    // Screenshot - ensure it can display full height
                    Image("always-allow-paste-setting")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
                    
                    // Note about accessing setting later
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This setting can always be accessed later in the omnibin settings")
                            .font(.system(size: isIPad ? 20 : 16))
                            .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                    }
                    .padding(.horizontal, 4)
                    
                    // Gear icon in its own container
                    Image(systemName: "gearshape")
                        .font(.system(size: isIPad ? 33 : 27, weight: .medium))
                        .foregroundColor(AppColors.Button.accentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            
            // Buttons
            VStack(spacing: 12) {
                // Open Settings button
                Button(action: onOpenSettings) {
                    HStack {
                        Image(systemName: "gearshape")
                            .font(.system(size: isIPad ? 22 : 18, weight: .medium))
                        Text("Open Settings")
                            .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 60 : 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppColors.Button.accentPrimary,
                                AppColors.Button.accentSecondary
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                // Later button
                Button(action: onDismiss) {
                    Text("Later")
                        .font(.system(size: isIPad ? 20 : 16, weight: .medium))
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 50 : 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDarkMode ? Color(white: 0.15) : Color(white: 0.95))
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .padding(.top, 8)
        }
        .frame(maxWidth: isIPad ? 600 : .infinity)
    }
}

#Preview {
    PastePermissionPopupView(
        onDismiss: {},
        onOpenSettings: {}
    )
}

