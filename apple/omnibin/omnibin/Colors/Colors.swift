import SwiftUI

struct AppColors {
    static let accent = Color(hex: 0xF2BA5C)
    static let onAccent = Color(hex: 0x121212)

    static func background(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x121212) : Color(hex: 0xFAFAFA)
    }

    static func surface(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x181818) : Color(hex: 0xFFFFFF)
    }

    static func border(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x262626) : Color(hex: 0xE4E4E4)
    }

    static func strongBorder(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x2E2E2E) : Color(hex: 0xD4D4D4)
    }

    static func primaryText(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0xEDEDED) : Color(hex: 0x171717)
    }

    static func secondaryText(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x9A9A9A) : Color(hex: 0x626262)
    }

    static func mutedText(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x808080) : Color(hex: 0x737373)
    }

    static func accentInk(isDarkMode: Bool) -> Color {
        isDarkMode ? accent : Color(hex: 0x8F5A0B)
    }

    static func media(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x222222) : Color(hex: 0xEFEFEF)
    }

    static func skeletonColor(isDarkMode: Bool) -> Color {
        media(isDarkMode: isDarkMode)
    }

    static func actionBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x222222) : Color(hex: 0xF0F0F0)
    }

    static func copiedBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x2E2618) : Color(hex: 0xFBEFD9)
    }

    static func danger(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0xF27474) : Color(hex: 0xDC2626)
    }

    static func dangerBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? Color(hex: 0x2A1C1C) : Color(hex: 0xFDECEC)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
