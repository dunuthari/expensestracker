import Foundation
import SwiftData
import ExpenseCore

enum SettingsKey {
    static let periodStartDay = "periodStartDay"
    static let lastMessageAt = "lastMessageAt"
}

/// The one on-device store, shared by the app and the Shortcuts intent.
enum Persistence {
    static let schema = Schema([TxGroup.self, LedgerEntry.self, UnparsedMessage.self])

    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
        } catch {
            fatalError("Could not open the on-device store: \(error)")
        }
    }()

    /// Adds starter groups the first time the app runs. The user can edit or delete all of them.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<TxGroup>())) ?? 0
        guard existing == 0 else { return }

        let expense: [(String, String, String)] = [
            ("Food", "orange", "fork.knife"),
            ("Transport", "indigo", "car.fill"),
            ("Bills", "teal", "bolt.fill"),
            ("Shopping", "rose", "bag.fill"),
            ("Gifts", "violet", "gift.fill")
        ]
        let income: [(String, String, String)] = [
            ("Salary", "moss", "briefcase.fill"),
            ("Freelance", "sky", "laptopcomputer"),
            ("Refund", "amber", "arrow.uturn.backward")
        ]
        for (index, item) in expense.enumerated() {
            context.insert(TxGroup(name: item.0, kind: .debit, colorKey: item.1, symbol: item.2, sortOrder: index))
        }
        for (index, item) in income.enumerated() {
            context.insert(TxGroup(name: item.0, kind: .credit, colorKey: item.1, symbol: item.2, sortOrder: index))
        }
        try? context.save()
    }
}
