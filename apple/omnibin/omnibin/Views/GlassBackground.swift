import SwiftUI
import UIKit

struct GlassBackground: View {
    var isDarkMode: Bool
    var cornerRadius: CGFloat
    var blurStyle: UIBlurEffect.Style
    var blurOpacity: CGFloat

    init(isDarkMode: Bool, cornerRadius: CGFloat = 12, blurStyle: UIBlurEffect.Style? = nil, blurOpacity: CGFloat? = nil) {
        self.isDarkMode = isDarkMode
        self.cornerRadius = cornerRadius
        if let blurStyle {
            self.blurStyle = blurStyle
        } else {
            self.blurStyle = isDarkMode ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        }
        if let blurOpacity {
            self.blurOpacity = blurOpacity
        } else {
            self.blurOpacity = isDarkMode ? 0.22 : 0.28
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        BlurView(style: blurStyle, opacity: blurOpacity)
            .clipShape(shape)
            .overlay(
                shape
                    .fill(AppColors.glassTint(isDarkMode: isDarkMode))
            )
            .overlay(
                shape
                    .fill(AppColors.glassHighlight(isDarkMode: isDarkMode))
                    .blendMode(.screen)
            )
            .overlay(
                shape
                    .stroke(AppColors.glassBorder(isDarkMode: isDarkMode), lineWidth: 1)
            )
    }
}

private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    let opacity: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.alpha = opacity
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.alpha = opacity
    }
}

