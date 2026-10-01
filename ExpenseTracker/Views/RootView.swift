import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var unparsed: [UnparsedMessage]

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            IncomeView()
                .tabItem { Label("Income", systemImage: "arrow.down.circle.fill") }
            ReportView()
                .tabItem { Label("Report", systemImage: "chart.pie.fill") }
            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .badge(unparsed.count)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            Persistence.seedIfNeeded(context)
            if await Notifier.authorizationStatus() == .notDetermined {
                _ = await Notifier.requestAuthorization()
            }
        }
    }
}
