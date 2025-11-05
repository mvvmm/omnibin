import SwiftUI

struct AppColors {
    // MARK: - Background Colors
    struct Background {
        // Light mode - matching web colors
        static let lightFrom = Color(red: 0.976, green: 0.969, blue: 0.949) // #f9f7f2
        static let lightVia = Color(red: 0.957, green: 0.949, blue: 0.925)  // #f4f2ec
        static let lightTo = Color(red: 0.910, green: 0.902, blue: 0.875)    // #e8e6df
        
        // Dark mode - matching web colors
        static let darkFrom = Color(red: 0.035, green: 0.035, blue: 0.043)  // #09090b
        static let darkVia = Color(red: 0.059, green: 0.059, blue: 0.063)   // #0f0f10
        static let darkTo = Color(red: 0.067, green: 0.067, blue: 0.075)    // #111113
    }
    
    // MARK: - Blob Colors
    struct Blob {
        // Light mode - matching web colors
        static let light1 = Color(red: 0.388, green: 0.404, blue: 0.945)    // indigo-500 #6366f1
        static let light2 = Color(red: 0.545, green: 0.361, blue: 0.965)    // violet-500 #8b5cf6
        static let light3 = Color(red: 0.659, green: 0.333, blue: 0.969)    // purple-500 #a855f7
        static let light4 = Color(red: 0.925, green: 0.282, blue: 0.600)    // pink-500 #ec4899
        static let light5 = Color(red: 0.231, green: 0.510, blue: 0.965)    // blue-500 #3b82f6
        static let light6 = Color(red: 0.024, green: 0.714, blue: 0.831)    // cyan-500 #06b6d4
        
        // Dark mode - matching web colors
        static let dark1 = Color(red: 0.310, green: 0.275, blue: 0.898)     // indigo-600 #4f46e5
        static let dark2 = Color(red: 0.427, green: 0.157, blue: 0.851)    // violet-700 #6d28d9
        static let dark3 = Color(red: 0.576, green: 0.200, blue: 0.918)     // purple-600 #9333ea
        static let dark4 = Color(red: 0.859, green: 0.153, blue: 0.467)    // pink-600 #db2777
        static let dark5 = Color(red: 0.145, green: 0.388, blue: 0.922)     // blue-600 #2563eb
        static let dark6 = Color(red: 0.031, green: 0.565, blue: 0.698)     // cyan-600 #0891b2
    }
    
    // MARK: - Card Colors
    struct Card {
        // Light mode - matching web: oklch(0.922 0 0) ≈ rgb(235, 235, 235)
        static let lightBackground = Color.white.opacity(0.6)
        static let lightBorder = Color(red: 0.922, green: 0.922, blue: 0.922) // oklch(0.922 0 0)
        
        // Dark mode - matching web: oklch(1 0 0 / 10%)
        static let darkBackground = Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.25) // zinc-900 with opacity
        static let darkBorder = Color.white.opacity(0.1)
        
        // Feature cards - use same subtle borders as regular cards
        static let lightFeatureBackground = Color.white.opacity(0.5)
        static let lightFeatureBorder = Color(red: 0.922, green: 0.922, blue: 0.922) // oklch(0.922 0 0)
        
        static let darkFeatureBackground = Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.3)
        static let darkFeatureBorder = Color.white.opacity(0.1) // Match regular dark border
    }
    
    // MARK: - Text Colors
    struct Text {
        // Light mode
        static let lightPrimary = Color.primary
        static let lightSecondary = Color.secondary
        static let lightMuted = Color(red: 0.64, green: 0.64, blue: 0.64) // neutral-400
        
        // Dark mode
        static let darkPrimary = Color.white
        static let darkSecondary = Color(red: 0.83, green: 0.83, blue: 0.83) // neutral-300
        static let darkMuted = Color(red: 0.64, green: 0.64, blue: 0.64)     // neutral-400
    }
    
    // MARK: - Button Colors
    struct Button {
        static let accentPrimary = Color(red: 0.35, green: 0.30, blue: 0.66)   // accent-primary
        static let accentSecondary = Color(red: 0.27, green: 0.42, blue: 0.62) // accent-secondary
    }
    
    // MARK: - Shadow Colors
    struct Shadow {
        // Light mode
        static let lightText = Color.white.opacity(0.3)
        static let lightCard = Color.gray.opacity(0.1)
        
        // Dark mode
        static let darkText = Color.black.opacity(0.3)
        static let darkCard = Color.black.opacity(0.4)
    }
    
    // MARK: - Grid Colors
    struct Grid {
        // Light mode
        static let light = Color.gray.opacity(0.06)
        
        // Dark mode
        static let dark = Color.white.opacity(0.06)
    }
}

// MARK: - Convenience Extensions
extension AppColors {
    static func backgroundGradient(isDarkMode: Bool) -> LinearGradient {
        let colors = isDarkMode ? 
            [Background.darkFrom, Background.darkVia, Background.darkTo] :
            [Background.lightFrom, Background.lightVia, Background.lightTo]
        
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func blob1Color(isDarkMode: Bool) -> Color {
        isDarkMode ? Blob.dark1 : Blob.light1
    }
    
    static func blob2Color(isDarkMode: Bool) -> Color {
        isDarkMode ? Blob.dark2 : Blob.light2
    }
    
    static func blob3Color(isDarkMode: Bool) -> Color {
        isDarkMode ? Blob.dark3 : Blob.light3
    }
    
    static func blob4Color(isDarkMode: Bool) -> Color {
        isDarkMode ? Blob.dark4 : Blob.light4
    }
    
    static func blob5Color(isDarkMode: Bool) -> Color {
        isDarkMode ? Blob.dark5 : Blob.light5
    }
    
    static func blob6Color(isDarkMode: Bool) -> Color {
        isDarkMode ? Blob.dark6 : Blob.light6
    }
    
    static func blobOpacity(isDarkMode: Bool) -> Double {
        isDarkMode ? 0.131 : 0.152  // Matching web blob opacity
    }
    
    static func cardBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? Card.darkBackground : Card.lightBackground
    }
    
    static func cardBorder(isDarkMode: Bool) -> Color {
        isDarkMode ? Card.darkBorder : Card.lightBorder
    }
    
    static func featureCardBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? Card.darkFeatureBackground : Card.lightFeatureBackground
    }
    
    static func featureCardBorder(isDarkMode: Bool) -> Color {
        isDarkMode ? Card.darkFeatureBorder : Card.lightFeatureBorder
    }
    
    static func primaryText(isDarkMode: Bool) -> Color {
        isDarkMode ? Text.darkPrimary : Text.lightPrimary
    }
    
    static func secondaryText(isDarkMode: Bool) -> Color {
        isDarkMode ? Text.darkSecondary : Text.lightSecondary
    }
    
    static func mutedText(isDarkMode: Bool) -> Color {
        isDarkMode ? Text.darkMuted : Text.lightMuted
    }
    
    static func textShadow(isDarkMode: Bool) -> Color {
        isDarkMode ? Shadow.darkText : Shadow.lightText
    }
    
    static func cardShadow(isDarkMode: Bool) -> Color {
        isDarkMode ? Shadow.darkCard : Shadow.lightCard
    }
    
    static func gridColor(isDarkMode: Bool) -> Color {
        isDarkMode ? Grid.dark : Grid.light
    }
}
