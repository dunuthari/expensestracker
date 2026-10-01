import Foundation

public struct ReportItem: Equatable, Sendable {
    public var groupID: String?
    public var amount: Decimal

    public init(groupID: String?, amount: Decimal) {
        self.groupID = groupID
        self.amount = amount
    }
}

public struct GroupTotal: Equatable, Identifiable, Sendable {
    /// The group's id, or `Report.ungroupedID` for items without a group.
    public let id: String
    public var total: Decimal
    public var count: Int
}

public enum Report {
    public static let ungroupedID = "none"

    /// Sums amounts per group, largest first. Items without a group collect under `ungroupedID`.
    public static func totals(_ items: [ReportItem]) -> [GroupTotal] {
        var sums: [String: Decimal] = [:]
        var counts: [String: Int] = [:]
        for item in items {
            let key = item.groupID ?? ungroupedID
            sums[key, default: 0] += item.amount
            counts[key, default: 0] += 1
        }
        return sums
            .map { GroupTotal(id: $0.key, total: $0.value, count: counts[$0.key] ?? 0) }
            .sorted { lhs, rhs in
                if lhs.total != rhs.total { return lhs.total > rhs.total }
                return lhs.id < rhs.id
            }
    }

    public static func sum(_ items: [ReportItem]) -> Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    /// Share of `total` as a fraction 0...1, safe for a zero total.
    public static func share(_ part: Decimal, of total: Decimal) -> Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: part / total).doubleValue
    }
}
