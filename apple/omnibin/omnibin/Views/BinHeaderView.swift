import SwiftUI

// MARK: - Bin Header View
struct BinHeaderView: View {
    let onLogout: () -> Void
    let onDeleteAccount: () -> Void
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            Text("Your Bin")
                .font(isIPad ? .system(size: 36, weight: .bold) : .largeTitle)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
            
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
                    Label("Get support", systemImage: "questionmark.circle")
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
                
                Button(action: {
                    onDeleteAccount()
                }) {
                    Label("Delete account", systemImage: "trash")
                }
                .foregroundColor(.red)
                
                Button(action: {
                    onLogout()
                }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: isIPad ? 24 : 16, weight: .medium))
                    .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    .frame(width: isIPad ? 70 : 46, height: isIPad ? 70 : 46)
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
            .compositingGroup()
        }
    }
}
