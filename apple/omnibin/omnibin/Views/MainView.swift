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
            
            // Blob effects - 6 blobs matching web version
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                
                // Use a reference size based on screen width (similar to rem-based sizing on web)
                // Scale down for mobile - slightly larger for better visibility
                let scaleFactor = max(screenWidth / 375.0, 0.8) * 0.55 // Increased scale for slightly larger blobs
                let baseRem: CGFloat = 16.0
                
                // Blob sizes - scaled down for mobile
                let blob1Width = 44 * baseRem * scaleFactor
                let blob1Height = 38 * baseRem * scaleFactor
                let blob2Width = 48 * baseRem * scaleFactor
                let blob2Height = 42 * baseRem * scaleFactor
                let blob3Width = 36 * baseRem * scaleFactor
                let blob3Height = 40 * baseRem * scaleFactor
                let blob4Width = 40 * baseRem * scaleFactor
                let blob4Height = 46 * baseRem * scaleFactor
                let blob5Width = 38 * baseRem * scaleFactor
                let blob5Height = 44 * baseRem * scaleFactor
                let blob6Width = 42 * baseRem * scaleFactor
                let blob6Height = 34 * baseRem * scaleFactor
                
                // Blur radius - scaled proportionally with blob size
                let blurRadius: CGFloat = 200 * scaleFactor * 0.7
                let baseOpacity = AppColors.blobOpacity(isDarkMode: isDarkMode)
                
                ZStack {
                    // Blob 1 - Top Left (adjusted to be more compact)
                    ZStack {
                        // Base blob with solid fill matching web
                        Ellipse()
                            .fill(AppColors.blob1Color(isDarkMode: isDarkMode).opacity(baseOpacity))
                            .frame(width: blob1Width, height: blob1Height)
                            .blur(radius: blurRadius)
                        
                        // Center enhancement - smaller, more opaque blob in center
                        Ellipse()
                            .fill(AppColors.blob1Color(isDarkMode: isDarkMode).opacity(baseOpacity * 1.8))
                            .frame(width: blob1Width * 0.4, height: blob1Height * 0.4)
                            .blur(radius: blurRadius * 0.6)
                    }
                    .position(x: screenWidth * 0.15, y: screenHeight * 0.15)
                    
                    // Blob 2 - Bottom Right (adjusted to be more compact)
                    ZStack {
                        Ellipse()
                            .fill(AppColors.blob2Color(isDarkMode: isDarkMode).opacity(baseOpacity))
                            .frame(width: blob2Width, height: blob2Height)
                            .blur(radius: blurRadius)
                        
                        Ellipse()
                            .fill(AppColors.blob2Color(isDarkMode: isDarkMode).opacity(baseOpacity * 1.8))
                            .frame(width: blob2Width * 0.4, height: blob2Height * 0.4)
                            .blur(radius: blurRadius * 0.6)
                    }
                    .position(x: screenWidth * 0.85, y: screenHeight * 0.85)
                    
                    // Blob 3 - Top Center (adjusted to be more compact)
                    ZStack {
                        Ellipse()
                            .fill(AppColors.blob3Color(isDarkMode: isDarkMode).opacity(baseOpacity))
                            .frame(width: blob3Width, height: blob3Height)
                            .blur(radius: blurRadius)
                        
                        Ellipse()
                            .fill(AppColors.blob3Color(isDarkMode: isDarkMode).opacity(baseOpacity * 1.8))
                            .frame(width: blob3Width * 0.4, height: blob3Height * 0.4)
                            .blur(radius: blurRadius * 0.6)
                    }
                    .position(x: screenWidth * 0.5, y: screenHeight * 0.25)
                    
                    // Blob 4 - Bottom Center (adjusted to be more compact)
                    ZStack {
                        Ellipse()
                            .fill(AppColors.blob4Color(isDarkMode: isDarkMode).opacity(baseOpacity))
                            .frame(width: blob4Width, height: blob4Height)
                            .blur(radius: blurRadius)
                        
                        Ellipse()
                            .fill(AppColors.blob4Color(isDarkMode: isDarkMode).opacity(baseOpacity * 1.8))
                            .frame(width: blob4Width * 0.4, height: blob4Height * 0.4)
                            .blur(radius: blurRadius * 0.6)
                    }
                    .position(x: screenWidth * 0.5, y: screenHeight * 0.75)
                    
                    // Blob 5 - Bottom Left (adjusted to be more compact)
                    ZStack {
                        Ellipse()
                            .fill(AppColors.blob5Color(isDarkMode: isDarkMode).opacity(baseOpacity))
                            .frame(width: blob5Width, height: blob5Height)
                            .blur(radius: blurRadius)
                        
                        Ellipse()
                            .fill(AppColors.blob5Color(isDarkMode: isDarkMode).opacity(baseOpacity * 1.8))
                            .frame(width: blob5Width * 0.4, height: blob5Height * 0.4)
                            .blur(radius: blurRadius * 0.6)
                    }
                    .position(x: screenWidth * 0.25, y: screenHeight * 0.75)
                    
                    // Blob 6 - Top Right (adjusted to be more compact)
                    ZStack {
                        Ellipse()
                            .fill(AppColors.blob6Color(isDarkMode: isDarkMode).opacity(baseOpacity))
                            .frame(width: blob6Width, height: blob6Height)
                            .blur(radius: blurRadius)
                        
                        Ellipse()
                            .fill(AppColors.blob6Color(isDarkMode: isDarkMode).opacity(baseOpacity * 1.8))
                            .frame(width: blob6Width * 0.4, height: blob6Height * 0.4)
                            .blur(radius: blurRadius * 0.6)
                    }
                    .position(x: screenWidth * 0.75, y: screenHeight * 0.35)
                }
            }
            .ignoresSafeArea()
            
            // Grid pattern
            GridPattern(isDarkMode: isDarkMode)
              .opacity(0.15)
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
                BinView(accessToken: authService.accessToken, onLogout: authService.logout, authService: authService)
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
