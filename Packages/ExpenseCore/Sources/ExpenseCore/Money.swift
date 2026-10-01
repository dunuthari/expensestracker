import Foundation

public enum Money {
    /// "LKR 1,500.00". Pass `signed: true` for money in: "+LKR 1,500.00".
    public static func format(_ amount: Decimal, currency: String = "LKR", signed: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let magnitude = amount < 0 ? -amount : amount
        let body = formatter.string(from: NSDecimalNumber(decimal: magnitude)) ?? "\(magnitude)"
        let sign = amount < 0 ? "-" : (signed ? "+" : "")
        return "\(sign)\(currency) \(body)"
    }
}
