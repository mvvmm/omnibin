import SwiftUI
import Auth0

struct MainView: View {
    @State var user: User?
    @State var accessToken: String?
    @State var isLoading = true
    @Environment(\.colorScheme) private var colorScheme
    
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
            Circle()
                .fill(AppColors.blob1Color(isDarkMode: isDarkMode))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: -150, y: -200)
                .opacity(AppColors.blobOpacity(isDarkMode: isDarkMode))
            
            Circle()
                .fill(AppColors.blob2Color(isDarkMode: isDarkMode))
                .frame(width: 450, height: 450)
                .blur(radius: 60)
                .offset(x: 200, y: 300)
                .opacity(AppColors.blobOpacity(isDarkMode: isDarkMode))
            
            // Grid pattern
            GridPattern(isDarkMode: isDarkMode)
                .opacity(0.2)
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
            } else if self.user != nil {
                BinView(accessToken: accessToken)
            } else {
                GeometryReader { geometry in
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
                                .shadow(radius: 20)
                                .padding(.horizontal, 24)
                            
                            // Main heading
                            Text("Copy. Paste. Anywhere.")
                                .font(.system(size: min(48, geometry.size.width * 0.12), weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                                .minimumScaleFactor(0.5)
                                .shadow(color: AppColors.textShadow(isDarkMode: isDarkMode), radius: 2)
                                .padding(.horizontal, 24)
                            
                            // Subtitle
                            Text("Seamless cross‑platform clipboard. Move text and files between devices with ease.")
                                .font(.system(size: min(18, geometry.size.width * 0.045), weight: .regular))
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.secondaryText(isDarkMode: isDarkMode))
                                .padding(.horizontal, 24)
                                .minimumScaleFactor(0.7)
                                .shadow(color: AppColors.textShadow(isDarkMode: isDarkMode).opacity(0.67), radius: 1)
                        
                            // Login button
                            Button(action: self.login) {
                                HStack(spacing: 8) {
                                    Text("Login to sync")
                                        .font(.system(size: min(18, geometry.size.width * 0.045), weight: .medium))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: min(16, geometry.size.width * 0.04), weight: .medium))
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
                            .onHover { isHovering in
                                #if os(macOS)
                                if isHovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                                #endif
                            }
                            
                            Spacer()
                                .frame(height: 10)
                            
                            // Feature cards
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
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
                                
                                FeatureCard(
                                    title: "Simple by design",
                                    description: "One click to get started.",
                                    isDarkMode: isDarkMode
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                            .padding(.horizontal, min(32, geometry.size.width * 0.08))
                            .padding(.top, 30)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.primaryText(isDarkMode: isDarkMode))
                .lineLimit(1)
            
            Text(description)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.mutedText(isDarkMode: isDarkMode))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 60) // Reduced minimum height
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
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
            case .failure(let error):
                // Try to renew if we have stored credentials but they're expired
                if credentialsManager.canRenew() {
                    credentialsManager.renew { renewResult in
                        switch renewResult {
                        case .success(let renewedCredentials):
                            self.user = User(from: renewedCredentials.idToken)
                            self.accessToken = renewedCredentials.accessToken
                            self.isLoading = false
                        case .failure(let renewError):
                            print("Failed to renew credentials: \(renewError)")
                            self.isLoading = false
                        }
                    }
                } else {
                    print("No stored credentials: \(error)")
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
                    self.credentialsManager.store(credentials: credentials)
                    self.user = User(from: credentials.idToken)
                    self.accessToken = credentials.accessToken
                    self.isLoading = false
                case .failure(let error):
                    print("Login failed with: \(error)")
                    self.isLoading = false
                }
            }
    }

    func logout() {
        // Clear stored credentials
        credentialsManager.clear()
        
        Auth0
            .webAuth()
            .useHTTPS() // Use a Universal Link logout URL on iOS 17.4+ / macOS 14.4+
            .clearSession { result in
                switch result {
                case .success:
                    self.user = nil
                    self.accessToken = nil
                    self.isLoading = false
                case .failure(let error):
                    print("Failed with: \(error)")
                    self.isLoading = false
                }
            }
    }
}
