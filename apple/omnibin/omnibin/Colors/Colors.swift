import SwiftUI

struct AppColors {
    // MARK: - Background Colors
    struct Background {
        // Light mode
        static let lightFrom = Color(red: 0.98, green: 0.98, blue: 0.98) // zinc-50
        static let lightVia = Color(red: 0.96, green: 0.96, blue: 0.96)  // zinc-100
        static let lightTo = Color(red: 0.90, green: 0.90, blue: 0.90)   // zinc-200
        
        // Dark mode
        static let darkFrom = Color(red: 0.04, green: 0.04, blue: 0.04)  // zinc-950
        static let darkVia = Color(red: 0.06, green: 0.06, blue: 0.06)   // near zinc-950
        static let darkTo = Color(red: 0.07, green: 0.07, blue: 0.07)    // near zinc-900
    }
    
    // MARK: - Blob Colors
    struct Blob {
        // Light mode
        static let light1 = Color(red: 0.65, green: 0.71, blue: 0.99)    // indigo-300
        static let light2 = Color(red: 0.77, green: 0.71, blue: 0.99)    // violet-300
        
        // Dark mode
        static let dark1 = Color(red: 0.31, green: 0.27, blue: 0.90)     // indigo-600
        static let dark2 = Color(red: 0.43, green: 0.16, blue: 0.85)     // violet-700
    }
    
    // MARK: - Card Colors
    struct Card {
        // Light mode
        static let lightBackground = Color.white.opacity(0.6)
        static let lightBorder = Color.gray.opacity(0.2)
        
        // Dark mode
        static let darkBackground = Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.25) // zinc-900 with opacity
        static let darkBorder = Color.white.opacity(0.1)
        
        // Feature cards
        static let lightFeatureBackground = Color.white.opacity(0.5)
        static let lightFeatureBorder = Color.gray.opacity(0.3)
        
        static let darkFeatureBackground = Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.3)
        static let darkFeatureBorder = Color.white.opacity(0.2)
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
    
    static func blobOpacity(isDarkMode: Bool) -> Double {
        isDarkMode ? 0.18 : 0.35
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
