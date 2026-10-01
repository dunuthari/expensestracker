import AppIntents
import SwiftData

/// The action a Shortcuts automation calls with the text of a bank SMS.
/// It runs in the background without opening the app.
struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense from Message"
    static var description = IntentDescription(
        "Reads a bank SMS and records it as an expense or as income. Expenses show a notification so you can pick a group."
    )
    static var openAppWhenRun = false

    @Parameter(title: "Message")
    var message: String

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$message)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        _ = await Ingestor.ingest(message, context: Persistence.container.mainContext)
        return .result()
    }
}

struct ExpenseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: ["Log an expense in \(.applicationName)"],
            shortTitle: "Log expense",
            systemImageName: "plus.circle"
        )
    }
}
