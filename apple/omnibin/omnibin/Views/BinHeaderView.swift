import SwiftUI

// MARK: - Bin Header View
struct BinHeaderView: View {
    let onLogout: () -> Void
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            Text("Your Bin")
                .font(.largeTitle)
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
                    Label("Support", systemImage: "questionmark.circle")
                }
                
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
    }
}
