import Foundation

/// Reads HNB debit alerts, for example:
/// `HNB SMS ALERT:INTERNET, Account:2090***2047,Location:Dialog Axiata PLC, LK,Amount(Approx.):159.00 LKR,Av.Bal:433408.92 LKR,Date:01.10.26,Time:09:50, Hot Line:0112462462`
///
/// The location can contain a comma, so every field is found by its label and never by splitting on commas.
enum DebitParser {
    static func parse(_ text: String, timeZone: TimeZone) -> ParsedTransaction? {
        guard text.range(of: "HNB SMS ALERT", options: [.caseInsensitive, .anchored]) != nil else {
            return nil
        }

        guard
            let amountMatch = Rx.firstMatch(#"Amount(?:\(Approx\.?\))?\s*:\s*([\d,]+(?:\.\d+)?)\s*([A-Z]{3})"#, in: text),
            let amount = Rx.decimal(amountMatch[1])
        else { return nil }
        let currency = amountMatch[2].uppercased()

        guard
            let d = Rx.firstMatch(#"Date\s*:\s*(\d{1,2})[./](\d{1,2})[./](\d{2,4})"#, in: text),
            let t = Rx.firstMatch(#"Time\s*:\s*(\d{1,2}):(\d{2})(?::(\d{2}))?"#, in: text),
            let date = Rx.date(
                day: d[1], month: d[2], year: d[3],
                hour: t[1], minute: t[2], second: t[3],
                timeZone: timeZone
            )
        else { return nil }

        let channel = Rx.firstMatch(#"HNB SMS ALERT\s*:\s*([^,]+)"#, in: text)?[1]
            .trimmingCharacters(in: .whitespaces) ?? ""
        let account = Rx.firstMatch(#"Account\s*:\s*([^,\s]+)"#, in: text)?[1] ?? ""
        let balance = Rx.firstMatch(#"Av\.?\s*Bal\s*:\s*([\d,]+(?:\.\d+)?)"#, in: text).flatMap { Rx.decimal($0[1]) }

        var merchant = Rx.firstMatch(#"Location\s*:\s*(.+?)\s*,\s*Amount"#, in: text)?[1]
            .trimmingCharacters(in: .whitespaces) ?? ""
        // "Dialog Axiata PLC, LK" -> drop the trailing country code.
        if let stripped = Rx.firstMatch(#"^(.*?)\s*,\s*[A-Z]{2}$"#, in: merchant)?[1], !stripped.isEmpty {
            merchant = stripped
        }
        if merchant.isEmpty { merchant = channel }

        return ParsedTransaction(
            kind: .debit,
            amount: amount,
            currency: currency,
            account: account,
            merchant: merchant,
            channel: channel,
            date: date,
            balance: balance,
            rawText: text
        )
    }
}
