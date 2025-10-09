import SwiftUI

// MARK: - Feature Card Component
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
