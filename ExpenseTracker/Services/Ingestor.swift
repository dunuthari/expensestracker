import Foundation
import SwiftData
import ExpenseCore

enum IngestResult {
    case recorded(LedgerEntry)
    case duplicate
    case unrecognized
}

/// Turns a bank SMS into saved data. Debits post a notification; credits are saved silently.
@MainActor
enum Ingestor {
    @discardableResult
    static func ingest(_ text: String, context: ModelContext, notify: Bool = true) async -> IngestResult {
        Persistence.seedIfNeeded(context)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: SettingsKey.lastMessageAt)

        switch BankMessageParser.parse(text) {
        case .unrecognized:
            context.insert(UnparsedMessage(text: text))
            try? context.save()
            return .unrecognized

        case .transaction(let parsed):
            let fingerprint = parsed.fingerprint
            let existing = (try? context.fetch(
                FetchDescriptor<LedgerEntry>(predicate: #Predicate { $0.fingerprint == fingerprint })
            )) ?? []
            if !existing.isEmpty { return .duplicate }

            let entry = LedgerEntry(from: parsed)
            context.insert(entry)
            try? context.save()

            if parsed.kind == .debit && notify {
                let groups = (try? context.fetch(FetchDescriptor<TxGroup>())) ?? []
                await Notifier.postExpense(entry, groups: groups)
            }
            return .recorded(entry)
        }
    }

    /// Tries a saved "Needs review" message again. Returns true when it is now saved and removed from the Inbox.
    static func retry(_ message: UnparsedMessage, context: ModelContext) async -> Bool {
        guard case .transaction = BankMessageParser.parse(message.text) else { return false }
        _ = await ingest(message.text, context: context, notify: false)
        context.delete(message)
        try? context.save()
        return true
    }
}
