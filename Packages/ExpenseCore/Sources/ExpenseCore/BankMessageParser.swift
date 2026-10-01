import Foundation

/// Entry point for reading a bank SMS. Each message format has its own parser;
/// they never share patterns.
public enum BankMessageParser {
    /// Bank messages carry Sri Lankan local time.
    public static let defaultTimeZone = TimeZone(identifier: "Asia/Colombo") ?? .current

    public static func parse(_ text: String, timeZone: TimeZone = defaultTimeZone) -> ParseResult {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let debit = DebitParser.parse(cleaned, timeZone: timeZone) {
            return .transaction(debit)
        }
        if let credit = CreditParser.parse(cleaned, timeZone: timeZone) {
            return .transaction(credit)
        }
        return .unrecognized
    }
}
