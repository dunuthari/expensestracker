import Foundation

/// Reads HNB credit alerts, for example:
/// `LKR 1,500.00 credited to Ac No:20902XXXXX47 on 29/09/26 21:47:35 Reason:CEFT-NETLFIX PAYMENT Bal:LKR 433,567.92 Protect from scams ...`
enum CreditParser {
    static func parse(_ text: String, timeZone: TimeZone) -> ParsedTransaction? {
        guard
            let head = Rx.firstMatch(#"^\s*([A-Z]{3})\s+([\d,]+(?:\.\d+)?)\s+credited\s+to"#, in: text),
            let amount = Rx.decimal(head[2])
        else { return nil }
        let currency = head[1].uppercased()

        guard
            let d = Rx.firstMatch(#"\bon\s+(\d{1,2})/(\d{1,2})/(\d{2,4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?"#, in: text),
            let date = Rx.date(
                day: d[1], month: d[2], year: d[3],
                hour: d[4], minute: d[5], second: d[6],
                timeZone: timeZone
            )
        else { return nil }

        let account = Rx.firstMatch(#"Ac\s*No\s*:\s*(\S+)"#, in: text)?[1] ?? ""
        let reason = Rx.firstMatch(#"Reason\s*:\s*(.+?)(?=\s+Bal\s*:|\s+Protect from|$)"#, in: text)?[1]
            .trimmingCharacters(in: .whitespaces) ?? "Credit"
        let channel = Rx.firstMatch(#"^([A-Z]{3,5})-"#, in: reason)?[1].uppercased() ?? "CREDIT"
        let balance = Rx.firstMatch(#"Bal\s*:\s*[A-Z]{3}\s*([\d,]+(?:\.\d+)?)"#, in: text).flatMap { Rx.decimal($0[1]) }

        return ParsedTransaction(
            kind: .credit,
            amount: amount,
            currency: currency,
            account: account,
            merchant: reason,
            channel: channel,
            date: date,
            balance: balance,
            rawText: text
        )
    }
}
