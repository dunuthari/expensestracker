import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(Persistence.container)
                .tint(Palette.ink)
        }
    }
}
