import Foundation

/// Sample bank messages in the real formats, stamped with the current time so each test is a new transaction.
enum SampleMessages {
    private static func formatted(_ date: Date, _ format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Colombo")
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    static func debit(now: Date = Date()) -> String {
        let date = formatted(now, "dd.MM.yy")
        let time = formatted(now, "HH:mm:ss")
        // Seconds keep two quick tests from being treated as the same alert.
        let shortTime = String(time.prefix(5))
        let seconds = Int(time.suffix(2)) ?? 0
        let amount = "\(100 + seconds).00"
        return "HNB SMS ALERT:INTERNET, Account:2090***2047,Location:Dialog Axiata PLC, LK,Amount(Approx.):\(amount) LKR,Av.Bal:433408.92 LKR,Date:\(date),Time:\(shortTime), Hot Line:0112462462"
    }

    static func credit(now: Date = Date()) -> String {
        let date = formatted(now, "dd/MM/yy")
        let time = formatted(now, "HH:mm:ss")
        return "LKR 1,500.00 credited to Ac No:20902XXXXX47 on \(date) \(time) Reason:CEFT-NETLFIX PAYMENT Bal:LKR 433,567.92 Protect from scams DO NOT SHARE ACCOUNT DETAILS /OTP Hotline 0112462462"
    }
}
