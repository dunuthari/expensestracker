import Foundation
import ExpenseCore

enum AppFormat {
    /// The currency totals are shown in. Entries are assumed to be in this currency.
    static let currency = "LKR"

    private static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    private static let longDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()

    static func day(_ date: Date) -> String { shortDate.string(from: date) }
    static func dayAndTime(_ date: Date) -> String { longDate.string(from: date) }

    static func money(_ amount: Decimal, signed: Bool = false) -> String {
        Money.format(amount, currency: currency, signed: signed)
    }
}

/// The period shown on Home, Income and Report: the custom date range when one is set, otherwise the calendar month.
func currentPeriod(startDay: Int, customStart: Double, customEnd: Double, now: Date = Date()) -> BillingPeriod {
    BillingPeriod.current(
        now: now,
        startDay: startDay,
        customStart: customStart > 0 ? Date(timeIntervalSince1970: customStart) : nil,
        customEnd: customEnd > 0 ? Date(timeIntervalSince1970: customEnd) : nil
    )
}
