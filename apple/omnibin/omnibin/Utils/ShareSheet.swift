import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Configure for iPad
        if let popover = controller.popoverPresentationController {
            // This will be set by the parent view if needed
            popover.permittedArrowDirections = []
        }
        
        // Don't exclude any activities - let iOS show all available options including Messages
        controller.excludedActivityTypes = nil
        
        controller.completionWithItemsHandler = { _, completed, _, error in
            DispatchQueue.main.async {
                isPresented = false
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

