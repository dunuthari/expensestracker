import Foundation
import SwiftData
import ExpenseCore

enum SettingsKey {
    static let periodStartDay = "periodStartDay"
    static let lastMessageAt = "lastMessageAt"
    /// A custom billing period, stored as seconds since 1970 (0 means not set).
    static let customStart = "customPeriodStart"
    static let customEnd = "customPeriodEnd"
    /// When on, a message with the same text as one already saved is skipped. Off by default: every message is saved.
    static let ignoreDuplicates = "ignoreDuplicates"
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

    /// Launch with `-demoData YES` to fill an empty store with sample entries (used for cloud screenshots).
    @MainActor
    static func seedDemoIfRequested(_ context: ModelContext) {
        guard UserDefaults.standard.bool(forKey: "demoData") else { return }
        seedIfNeeded(context)
        guard ((try? context.fetchCount(FetchDescriptor<LedgerEntry>())) ?? 0) == 0 else { return }

        let groups = (try? context.fetch(FetchDescriptor<TxGroup>())) ?? []
        func group(_ name: String) -> TxGroup? { groups.first { $0.name == name } }
        let now = Date()

        let expenses: [(String, String, String, String?)] = [
            ("Keells Super", "POS", "4820.50", "Food"),
            ("Dialog Axiata PLC", "INTERNET", "159.00", nil),
            ("PickMe", "INTERNET", "1250.00", "Transport"),
            ("CEB Electricity", "INTERNET", "8400.00", "Bills"),
            ("Cargills Food City", "POS", "3120.75", "Food"),
            ("Odel", "POS", "12500.00", "Shopping"),
            ("Uber", "INTERNET", "980.00", "Transport"),
            ("Gift Shop", "POS", "3000.00", "Gifts"),
            ("Burger King", "POS", "2150.00", "Food")
        ]
        for (index, item) in expenses.enumerated() {
            context.insert(LedgerEntry(
                kind: .debit,
                amount: Decimal(string: item.2) ?? 0,
                currency: "LKR",
                merchant: item.0,
                channel: item.1,
                date: now.addingTimeInterval(-Double(index + 1) * 60),
                group: item.3.flatMap { group($0) }
            ))
        }

        let credits: [(String, String, String, String?)] = [
            ("SALARY - ACME PVT LTD", "CEFT", "120000.00", "Salary"),
            ("Freelance - Design", "CEFT", "25000.00", "Freelance"),
            ("CEFT-NETLFIX PAYMENT", "CEFT", "1500.00", nil)
        ]
        for (index, item) in credits.enumerated() {
            context.insert(LedgerEntry(
                kind: .credit,
                amount: Decimal(string: item.2) ?? 0,
                currency: "LKR",
                merchant: item.0,
                channel: item.1,
                date: now.addingTimeInterval(-Double(index + 20) * 60),
                group: item.3.flatMap { group($0) }
            ))
        }

        context.insert(UnparsedMessage(text: "HNB SMS ALERT:ATM, Account:2090***2047,Location:ATM Colombo 03, LK,Withdrawal:5,000.00 LKR"))
        try? context.save()
    }
}
