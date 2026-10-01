import Foundation
import SwiftData
import ExpenseCore

/// A user-managed group. Expense groups (kind .debit) and income groups (kind .credit) are separate lists.
@Model
final class TxGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var colorKey: String
    var symbol: String
    var sortOrder: Int
    @Relationship(deleteRule: .nullify, inverse: \LedgerEntry.group) var entries: [LedgerEntry] = []

    init(name: String, kind: TransactionKind, colorKey: String, symbol: String, sortOrder: Int) {
        self.id = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.colorKey = colorKey
        self.symbol = symbol
        self.sortOrder = sortOrder
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .debit }
        set { kindRaw = newValue.rawValue }
    }
}

/// One expense (debit) or income (credit). Each entry belongs to at most one group.
@Model
final class LedgerEntry {
    @Attribute(.unique) var id: UUID
    var kindRaw: String
    var amount: Decimal
    var currency: String
    var merchant: String
    var channel: String
    var account: String
    var date: Date
    var balance: Decimal?
    var note: String
    var rawText: String
    var fingerprint: String
    var createdAt: Date
    var group: TxGroup?

    init(
        kind: TransactionKind,
        amount: Decimal,
        currency: String,
        merchant: String,
        channel: String = "",
        account: String = "",
        date: Date,
        balance: Decimal? = nil,
        note: String = "",
        rawText: String = "",
        fingerprint: String = "",
        group: TxGroup? = nil
    ) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.channel = channel
        self.account = account
        self.date = date
        self.balance = balance
        self.note = note
        self.rawText = rawText
        self.fingerprint = fingerprint
        self.createdAt = Date()
        self.group = group
    }

    convenience init(from parsed: ParsedTransaction) {
        self.init(
            kind: parsed.kind,
            amount: parsed.amount,
            currency: parsed.currency,
            merchant: parsed.merchant,
            channel: parsed.channel,
            account: parsed.account,
            date: parsed.date,
            balance: parsed.balance,
            rawText: parsed.rawText,
            fingerprint: parsed.fingerprint
        )
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .debit }
        set { kindRaw = newValue.rawValue }
    }
}

/// A message the parser could not read. It waits in the Inbox as "Needs review".
@Model
final class UnparsedMessage {
    @Attribute(.unique) var id: UUID
    var text: String
    var receivedAt: Date

    init(text: String, receivedAt: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.receivedAt = receivedAt
    }
}
