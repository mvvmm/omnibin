import SwiftUI

@main
struct omnibinApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Post notification when app becomes active
                        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
                    }
                }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}
