import Foundation

/// A billing period that starts on the same day every month.
/// `start` is inclusive and `end` is exclusive (the start of the next period).
public struct BillingPeriod: Equatable, Sendable {
    public let start: Date
    public let end: Date
    public let startDay: Int

    /// Start days are limited to 1...28 so every month has the day.
    public static let startDayRange = 1...28

    public static func containing(_ date: Date, startDay: Int, calendar: Calendar = .current) -> BillingPeriod {
        let day = min(max(startDay, startDayRange.lowerBound), startDayRange.upperBound)
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        var anchor = calendar.date(from: DateComponents(year: parts.year, month: parts.month, day: day)) ?? date
        if (parts.day ?? 1) < day {
            anchor = calendar.date(byAdding: .month, value: -1, to: anchor) ?? anchor
        }
        let end = calendar.date(byAdding: .month, value: 1, to: anchor) ?? anchor
        return BillingPeriod(start: anchor, end: end, startDay: day)
    }

    /// The period `months` before (negative) or after (positive) this one.
    public func shifted(by months: Int, calendar: Calendar = .current) -> BillingPeriod {
        let newStart = calendar.date(byAdding: .month, value: months, to: start) ?? start
        let newEnd = calendar.date(byAdding: .month, value: 1, to: newStart) ?? newStart
        return BillingPeriod(start: newStart, end: newEnd, startDay: startDay)
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    /// "25 Sep – 24 Oct", or "October 2026" for periods that follow the calendar month.
    public func label(calendar: Calendar = .current, locale: Locale = Locale(identifier: "en_GB")) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        if startDay == 1 {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: start)
        }
        formatter.dateFormat = "d MMM"
        let lastDay = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        return "\(formatter.string(from: start)) – \(formatter.string(from: lastDay))"
    }
}
