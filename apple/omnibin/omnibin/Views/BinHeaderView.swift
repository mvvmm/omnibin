import SwiftUI

// MARK: - Bin Header View
struct BinHeaderView: View {
    let onLogout: () -> Void
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
                    if let url = URL(string: "https://www.omnib.in") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Open on the web", systemImage: "safari")
                }
                
                Button(action: {
                    if let url = URL(string: "https://www.omnib.in/support") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Get support", systemImage: "questionmark.circle")
                }
                
                Button(action: {
                    if let url = URL(string: "https://www.omnib.in/privacy-policy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Label("Privacy policy", systemImage: "lock.document")
                }
                
                Button(action: {
                    onLogout()
                }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: isIPad ? 30 : 20, weight: .medium))
                    .foregroundColor(AppColors.Button.accentPrimary)
            }
        }
    }
}
