import SwiftUI

struct MainView: View {
    @StateObject private var authService = MainViewAuthService()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    var body: some View {
        ZStack {
            AppColors.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()

            if authService.isLoading {
                ProgressView()
                    .tint(AppColors.secondaryText(isDarkMode: isDarkMode))
            } else if authService.user != nil {
                BinView(accessToken: authService.accessToken, onLogout: authService.logout, authService: authService)
                    .padding(.top, horizontalSizeClass == .regular ? 48 : 0)
            } else {
                LoginView(onLogin: authService.login, isDarkMode: isDarkMode)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: colorScheme)
        .onAppear {
            authService.checkStoredCredentials()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
            // Refresh credentials when app becomes active
            if authService.user != nil {
                authService.checkStoredCredentials()
            }
        }
    }
}

// MARK: - Login View
private struct LoginView: View {
    let onLogin: () -> Void
    let isDarkMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Image("binboy")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 160 : 120, height: isIPad ? 160 : 120)
                    .accessibilityLabel("omnibin mascot")

                Text("Copy. Paste. Anywhere.")
                    .font(.system(size: isIPad ? 64 : 42, weight: .semibold))
                    .tracking(isIPad ? -2 : -1.4)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                    .minimumScaleFactor(0.6)

                Text("A shared clipboard for all your devices. Move text, images, and files between them in one tap.")
                    .font(.system(size: isIPad ? 20 : 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                    .frame(maxWidth: isIPad ? 460 : 320)
            }

            Spacer()

            VStack(spacing: 6) {
                Button(action: onLogin) {
                    Text("Log in to sync")
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

                HStack(spacing: 4) {
                    footerLink("Privacy Policy", url: "https://omnib.in/privacy-policy")
                    footerLink("Support", url: "https://omnib.in/support")
                }
            }
            .frame(maxWidth: 480)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func footerLink(_ title: String, url: String) -> some View {
        Link(title, destination: URL(string: url)!)
            .font(.system(size: 13))
            .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
            .padding(.horizontal, 10)
            .frame(minHeight: 44)
    }
}
