import SwiftUI
import Auth0

struct MainView: View {
    @State var user: User?
    @State var accessToken: String?
    @State var isLoading = true
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    
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
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                }
                .padding(.top, horizontalSizeClass == .regular ? 48 : 0)
            } else if self.user != nil {
                BinView(accessToken: accessToken, onLogout: logout)
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
                            Text("Seamless cross‑platform clipboard. Move text and files between devices with ease.")
                                .font(.system(size: min(isRegularWidth ? 32 : 18, geometry.size.width * 0.045), weight: .regular))
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                                .padding(.horizontal, 24)
                                .minimumScaleFactor(0.7)
                                .shadow(color: AppColors.textShadow(isDarkMode: isDarkMode).opacity(0.67), radius: 1)
                        
                            // Login button
                            Button(action: self.login) {
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
                                        title: "Fast, secure sync",
                                        description: "Backed by modern auth and storage.",
                                        isDarkMode: isDarkMode
                                    )
                                    
                                    FeatureCard(
                                        title: "Multi‑device",
                                        description: "Use it on the web, Windows 11, iOS, macOS, and iPadOS.",
                                        isDarkMode: isDarkMode
                                    )
                                }
                                .frame(maxHeight: .infinity, alignment: .top)
                                
                                FeatureCard(
                                    title: "Simple by design",
                                    description: "One click to get started.",
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
            checkStoredCredentials()
        }
        .onReceive(NotificationCenter.default.publisher(for: .appDidBecomeActive)) { _ in
            // Refresh credentials when app becomes active
            if user != nil {
                checkStoredCredentials()
            }
        }
    }
}

struct GridPattern: View {
    let isDarkMode: Bool
    
    var body: some View {
        Canvas { context, size in
            let gridSize: CGFloat = 36
            let lineWidth: CGFloat = 1
            let gridColor = AppColors.gridColor(isDarkMode: isDarkMode)
            
            // Vertical lines
            for x in stride(from: 0, through: size.width, by: gridSize) {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    },
                    with: .color(gridColor),
                    lineWidth: lineWidth
                )
            }
            
            // Horizontal lines
            for y in stride(from: 0, through: size.height, by: gridSize) {
                context.stroke(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    },
                    with: .color(gridColor),
                    lineWidth: lineWidth
                )
            }
        }
    }
}


struct FeatureCard: View {
    let title: String
    let description: String
    let isDarkMode: Bool
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        let isRegularWidth = horizontalSizeClass == .regular
        let horizontalPadding: CGFloat = isRegularWidth ? 20 : 12
        let verticalPadding: CGFloat = isRegularWidth ? 16 : 12
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: isRegularWidth ? 24 : 15, weight: .semibold))
                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                .lineLimit(1)
            
            Text(description)
                .font(.system(size: isRegularWidth ? 16 : 13, weight: .regular))
                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.featureCardBackground(isDarkMode: isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.featureCardBorder(isDarkMode: isDarkMode), lineWidth: 1)
                )
                .shadow(
                    color: AppColors.cardShadow(isDarkMode: isDarkMode), 
                    radius: 12, 
                    x: 0, 
                    y: 6
                )
        )
    }
}

extension MainView {
    func checkStoredCredentials() {
        credentialsManager.credentials { result in
            switch result {
            case .success(let credentials):
                self.user = User(from: credentials.idToken)
                self.accessToken = credentials.accessToken
                self.isLoading = false
            case .failure(_):
                // Try to renew if we have stored credentials but they're expired
                if credentialsManager.canRenew() {
                    credentialsManager.renew { renewResult in
                        switch renewResult {
                        case .success(let renewedCredentials):
                            self.user = User(from: renewedCredentials.idToken)
                            self.accessToken = renewedCredentials.accessToken
                            
                            // Update access token in shared Keychain
                            SecureStorageManager.shared.setAccessToken(renewedCredentials.accessToken)
                            
                            // Also store in UserDefaults for debugging
                            if let sharedDefaults = UserDefaults(suiteName: "group.in.omnib.omnibin") {
                                sharedDefaults.set(renewedCredentials.accessToken, forKey: "access_token")
                            }
                            
                            self.isLoading = false
                        case .failure(_):
                            self.isLoading = false
                        }
                    }
                } else {
                    self.isLoading = false
                }
            }
        }
    }
    
    func login() {
        Auth0
            .webAuth()
            .useHTTPS() // Use a Universal Link callback URL on iOS 17.4+ / macOS 14.4+
            .audience("https://omnib.in/api")
            .scope("openid profile email offline_access")
            .start { result in
                switch result {
            case .success(let credentials):
                // Store credentials for future use
                _ = self.credentialsManager.store(credentials: credentials)
                self.user = User(from: credentials.idToken)
                self.accessToken = credentials.accessToken
                
        // Store access token in shared Keychain for Share Extension
        SecureStorageManager.shared.setAccessToken(credentials.accessToken)
        
        // Also store in UserDefaults for debugging
        if let sharedDefaults = UserDefaults(suiteName: "group.in.omnib.omnibin") {
            sharedDefaults.set(credentials.accessToken, forKey: "access_token")
        }
                
                self.isLoading = false
                case .failure(_):
                    self.isLoading = false
                }
            }
    }

    func logout() {
        // Clear stored credentials
        _ = credentialsManager.clear()
        
        // Clear shared Keychain
        SecureStorageManager.shared.deleteAccessToken()
        SecureStorageManager.shared.clearUserInfo()
        
        Auth0
            .webAuth()
            .useHTTPS() // Use a Universal Link logout URL on iOS 17.4+ / macOS 14.4+
            .clearSession { result in
                switch result {
                case .success:
                    self.user = nil
                    self.accessToken = nil
                    self.isLoading = false
                case .failure(_):
                    self.isLoading = false
                }
            }
    }
}
