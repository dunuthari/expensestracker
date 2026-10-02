import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var unparsed: [UnparsedMessage]
    /// `-startTab N` on launch opens tab N (used for cloud screenshots).
    @State private var selection = UserDefaults.standard.integer(forKey: "startTab")

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            IncomeView()
                .tabItem { Label("Income", systemImage: "arrow.down.circle.fill") }
                .tag(1)
            ReportView()
                .tabItem { Label("Report", systemImage: "chart.pie.fill") }
                .tag(2)
            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .badge(unparsed.count)
                .tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .task {
            Persistence.seedIfNeeded(context)
            Persistence.seedDemoIfRequested(context)
            Notifier.refreshCategory()
            // Demo launches skip the permission alert so screenshots stay clean.
            if !UserDefaults.standard.bool(forKey: "demoData"),
               await Notifier.authorizationStatus() == .notDetermined {
                _ = await Notifier.requestAuthorization()
            }
        }
    }
}
