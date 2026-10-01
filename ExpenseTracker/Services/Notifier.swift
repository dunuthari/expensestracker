import Foundation
import SwiftData
import UserNotifications
import ExpenseCore

/// Local notifications for new expenses. Credits never notify.
@MainActor
enum Notifier {
    static let categoryID = "EXPENSE_CATEGORIZE"
    static let groupPrefix = "group:"
    static let reasonAction = "reason"
    /// Banners show about four actions; three groups plus "Add reason…" fit.
    static let maxGroupActions = 3

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Registers the action buttons for the groups used most.
    static func registerCategory(groups: [TxGroup]) {
        let top = groups
            .filter { $0.kind == .debit }
            .sorted { lhs, rhs in
                if lhs.entries.count != rhs.entries.count { return lhs.entries.count > rhs.entries.count }
                return lhs.sortOrder < rhs.sortOrder
            }
            .prefix(maxGroupActions)

        var actions: [UNNotificationAction] = top.map {
            UNNotificationAction(identifier: groupPrefix + $0.id.uuidString, title: $0.name, options: [])
        }
        actions.append(
            UNTextInputNotificationAction(
                identifier: reasonAction,
                title: "Add reason…",
                options: [],
                textInputButtonTitle: "Save",
                textInputPlaceholder: "Reason"
            )
        )
        let category = UNNotificationCategory(
            identifier: categoryID,
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func postExpense(_ entry: LedgerEntry, groups: [TxGroup]) async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        registerCategory(groups: groups)

        let content = UNMutableNotificationContent()
        content.title = "\(Money.format(entry.amount, currency: entry.currency)) spent"
        content.body = [entry.merchant, entry.channel].filter { !$0.isEmpty }.joined(separator: " · ")
        content.categoryIdentifier = categoryID
        content.userInfo = ["entryID": entry.id.uuidString]
        content.sound = .default
        content.threadIdentifier = "expenses"

        let request = UNNotificationRequest(identifier: entry.id.uuidString, content: content, trigger: nil)
        try? await center.add(request)
    }

    /// Applies a tapped notification action to the saved entry. No confirmation: save and finish.
    static func handle(actionID: String, entryID: String?, text: String?) {
        guard let entryID, let uuid = UUID(uuidString: entryID) else { return }
        let context = Persistence.container.mainContext
        guard let entry = try? context.fetch(
            FetchDescriptor<LedgerEntry>(predicate: #Predicate { $0.id == uuid })
        ).first else { return }

        if actionID.hasPrefix(groupPrefix) {
            let raw = String(actionID.dropFirst(groupPrefix.count))
            if let groupID = UUID(uuidString: raw),
               let group = try? context.fetch(
                   FetchDescriptor<TxGroup>(predicate: #Predicate { $0.id == groupID })
               ).first {
                entry.group = group
            }
        } else if actionID == reasonAction {
            let reason = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if !reason.isEmpty { entry.note = reason }
        }
        try? context.save()
    }
}
