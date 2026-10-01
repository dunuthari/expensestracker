import Foundation

/// Whether money left the account (debit, an expense) or arrived (credit, income).
public enum TransactionKind: String, Codable, Sendable {
    case debit
    case credit
}

/// One bank alert, read into plain values.
public struct ParsedTransaction: Equatable, Sendable {
    public var kind: TransactionKind
    public var amount: Decimal
    public var currency: String
    public var account: String
    /// Debit: the merchant or location. Credit: the reason text.
    public var merchant: String
    /// Debit: INTERNET, POS and so on. Credit: the prefix of the reason, such as CEFT.
    public var channel: String
    public var date: Date
    public var balance: Decimal?
    public var rawText: String

    public init(
        kind: TransactionKind,
        amount: Decimal,
        currency: String,
        account: String,
        merchant: String,
        channel: String,
        date: Date,
        balance: Decimal?,
        rawText: String
    ) {
        self.kind = kind
        self.amount = amount
        self.currency = currency
        self.account = account
        self.merchant = merchant
        self.channel = channel
        self.date = date
        self.balance = balance
        self.rawText = rawText
    }

    /// Identifies the same alert if it is delivered twice.
    public var fingerprint: String {
        let balanceText = balance.map { "\($0)" } ?? "-"
        return [
            kind.rawValue,
            account,
            currency,
            "\(amount)",
            "\(Int(date.timeIntervalSince1970))",
            balanceText
        ].joined(separator: "|")
    }
}

public enum ParseResult: Equatable, Sendable {
    case transaction(ParsedTransaction)
    case unrecognized
}
