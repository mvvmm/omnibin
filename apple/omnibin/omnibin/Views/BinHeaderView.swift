import SwiftUI

// MARK: - Bin Header View
struct BinHeaderView: View {
    let onLogout: () -> Void
    let onDeleteAccount: () -> Void
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image("binboy")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 34 : 28, height: isIPad ? 34 : 28)
                    .accessibilityHidden(true)
                Text("omnibin")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .tracking(-0.2)
                    .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            Menu {
                Button(action: {
                    if let url = URL(string: "https://omnib.in") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Open on the web", systemImage: "safari")
                }
                
                Button(action: {
                    if let url = URL(string: "https://omnib.in/support") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Support", systemImage: "questionmark.circle")
                }
                
                Button(action: {
                    if let url = URL(string: "https://omnib.in/support") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Request a feature", systemImage: "lightbulb")
                }
                
                Button(action: {
                    if let url = URL(string: "https://omnib.in/support") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Submit a bug", systemImage: "ant")
                }
                
                Button(action: {
                    if let url = URL(string: "https://omnib.in/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Privacy policy", systemImage: "lock.document")
                }
                
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    Label("Always allow paste", systemImage: "doc.on.clipboard")
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    onDeleteAccount()
                }) {
                    Label("Delete account", systemImage: "trash")
                }
                
                Button(action: {
                    onLogout()
                }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: isIPad ? 22 : 19, weight: .regular))
                    .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
        }
    }
}
