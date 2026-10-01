import Foundation

enum Rx {
    /// Returns the full match followed by each capture group (empty string when a group did not take part).
    static func firstMatch(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        return (0..<match.numberOfRanges).map { index in
            let nsRange = match.range(at: index)
            guard nsRange.location != NSNotFound, let swiftRange = Range(nsRange, in: text) else {
                return ""
            }
            return String(text[swiftRange])
        }
    }

    static func decimal(_ text: String) -> Decimal? {
        Decimal(
            string: text.replacingOccurrences(of: ",", with: ""),
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    static func date(
        day: String,
        month: String,
        year: String,
        hour: String,
        minute: String,
        second: String,
        timeZone: TimeZone
    ) -> Date? {
        guard
            let d = Int(day), let m = Int(month), var y = Int(year),
            let h = Int(hour), let min = Int(minute)
        else { return nil }
        let s = Int(second) ?? 0
        if y < 100 { y += 2000 }
        guard (1...12).contains(m), (1...31).contains(d), (0...23).contains(h), (0...59).contains(min), (0...59).contains(s) else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))
    }
}
