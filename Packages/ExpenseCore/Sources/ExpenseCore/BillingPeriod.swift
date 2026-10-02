import Foundation

/// A billing period that starts on the same day every month.
/// `start` is inclusive and `end` is exclusive (the start of the next period).
public struct BillingPeriod: Equatable, Sendable {
    public let start: Date
    public let end: Date
    public let startDay: Int
    /// True for a period the user set with a start and end date.
    public let isCustom: Bool

    init(start: Date, end: Date, startDay: Int, isCustom: Bool = false) {
        self.start = start
        self.end = end
        self.startDay = startDay
        self.isCustom = isCustom
    }

    /// Start days are limited to 1...28 so every month has the day.
    public static let startDayRange = 1...28

    /// A period from `start` to the end of `endInclusive`. Returns nil when the end day is before the start day.
    public static func custom(start: Date, endInclusive: Date, calendar: Calendar = .current) -> BillingPeriod? {
        let first = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: endInclusive)
        guard last >= first, let end = calendar.date(byAdding: .day, value: 1, to: last) else { return nil }
        return BillingPeriod(start: first, end: end, startDay: 1, isCustom: true)
    }

    /// The period to show: the custom range when both dates are set and valid, otherwise the month-based period.
    public static func current(
        now: Date = Date(),
        startDay: Int = 1,
        customStart: Date?,
        customEnd: Date?,
        calendar: Calendar = .current
    ) -> BillingPeriod {
        if let customStart, let customEnd,
           let period = custom(start: customStart, endInclusive: customEnd, calendar: calendar) {
            return period
        }
        return containing(now, startDay: startDay, calendar: calendar)
    }

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
    /// A custom period moves by its own length in days instead.
    public func shifted(by months: Int, calendar: Calendar = .current) -> BillingPeriod {
        if isCustom {
            let days = max(calendar.dateComponents([.day], from: start, to: end).day ?? 1, 1)
            let newStart = calendar.date(byAdding: .day, value: days * months, to: start) ?? start
            let newEnd = calendar.date(byAdding: .day, value: days, to: newStart) ?? newStart
            return BillingPeriod(start: newStart, end: newEnd, startDay: startDay, isCustom: true)
        }
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
        if isCustom {
            formatter.dateFormat = "d MMM yyyy"
            let lastDay = calendar.date(byAdding: .day, value: -1, to: end) ?? end
            return "\(formatter.string(from: start)) – \(formatter.string(from: lastDay))"
        }
        if startDay == 1 {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: start)
        }
        formatter.dateFormat = "d MMM"
        let lastDay = calendar.date(byAdding: .day, value: -1, to: end) ?? end
        return "\(formatter.string(from: start)) – \(formatter.string(from: lastDay))"
    }
}
