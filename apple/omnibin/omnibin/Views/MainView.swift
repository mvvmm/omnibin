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
            // Background gradient
            AppColors.backgroundGradient(isDarkMode: isDarkMode)
                .ignoresSafeArea()
            
            // Blob effects
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                let blobSize = min(screenWidth, screenHeight) * 0.6
                
                Circle()
                    .fill(AppColors.blob1Color(isDarkMode: isDarkMode))
                    .frame(width: blobSize, height: blobSize)
                    .blur(radius: blobSize * 0.15)
                    .offset(x: -screenWidth * 0.1, y: screenHeight * 0.1)
                    .opacity(AppColors.blobOpacity(isDarkMode: isDarkMode))
                
                Circle()
                    .fill(AppColors.blob2Color(isDarkMode: isDarkMode))
                    .frame(width: blobSize * 1.1, height: blobSize * 1.1)
                    .blur(radius: blobSize * 0.15)
                    .offset(x: screenWidth * 0.4, y: screenHeight * 0.6)
                    .opacity(AppColors.blobOpacity(isDarkMode: isDarkMode))
            }
            
            // Grid pattern
            GridPattern(isDarkMode: isDarkMode)
                .opacity(isDarkMode ? 0.3 : 1)
                .ignoresSafeArea()
            
            // Main content
            if authService.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                }
                .padding(.top, horizontalSizeClass == .regular ? 48 : 0)
            } else if authService.user != nil {
                BinView(accessToken: authService.accessToken, onLogout: authService.logout)
                    .padding(.top, horizontalSizeClass == .regular ? 48 : 0)
            } else {
                GeometryReader { geometry in
                    let isRegularWidth = (horizontalSizeClass == .regular) || geometry.size.width >= 700
                    ScrollView {
                        VStack(spacing: 0) {
                            // Main content
                            VStack(spacing: min(40, geometry.size.height * 0.05)) {
                            // Logo
                            Image("omnibin-logo6")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: min(720, geometry.size.width * 0.9))
                                .frame(maxHeight: 200)
                                .frame(minHeight: 120)
                                .padding(.horizontal, 24)
                            
                            // Main heading
                            Text("Copy. Paste. Anywhere.")
                                .font(.system(size: min(isRegularWidth ? 90 : 48, geometry.size.width * 0.12), weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                .minimumScaleFactor(0.5)
                                .shadow(color: AppColors.textShadow(isDarkMode: isDarkMode), radius: 2)
                                .padding(.horizontal, 24)
                            
                            // Subtitle
                            Text("Seamless cross‑platform clipboard. Move text, images, and files between devices with ease.")
                                .font(.system(size: min(isRegularWidth ? 32 : 18, geometry.size.width * 0.045), weight: .regular))
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                                .padding(.horizontal, 24)
                                .minimumScaleFactor(0.7)
                                .shadow(color: AppColors.textShadow(isDarkMode: isDarkMode).opacity(0.67), radius: 1)
                        
                            // Login button
                            Button(action: authService.login) {
                                HStack(spacing: 8) {
                                    Text("Login to sync")
                                        .font(.system(size: min(isRegularWidth ? 28 : 18, geometry.size.width * 0.045), weight: .medium))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: min(isRegularWidth ? 24 : 16, geometry.size.width * 0.04), weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, min(32, geometry.size.width * 0.08))
                                .padding(.vertical, min(16, geometry.size.height * 0.02))
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
                                .cornerRadius(10)
                                .shadow(color: AppColors.Button.accentPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                                .frame(height: 10)
                            
                            // Feature cards
                            VStack(spacing: isRegularWidth ? 16 : 8) {
                                HStack(spacing: isRegularWidth ? 12 : 8) {
                                    FeatureCard(
                                        title: "Cross-platform",
                                        description: "Share one bin on all devices.",
                                        isDarkMode: isDarkMode
                                    )

                                    FeatureCard(
                                    title: "Effortless",
                                    description: "One click copy and paste.",
                                    isDarkMode: isDarkMode
                                )
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                                
                                FeatureCard(
                                        title: "Fast and secure",
                                        description: "Backed by modern auth and storage.",
                                        isDarkMode: isDarkMode
                                    )
                            }
                            .padding(.horizontal, isRegularWidth ? 24 : 8)
                        }
                            .padding(.horizontal, min(32, geometry.size.width * 0.08))
                            .padding(.top, 30 + (isRegularWidth ? 48 : 0))
                            .padding(.bottom, 30)
                        }
                    }
                }
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
