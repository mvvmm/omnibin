import SwiftUI

// MARK: - Grid Pattern Background
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
