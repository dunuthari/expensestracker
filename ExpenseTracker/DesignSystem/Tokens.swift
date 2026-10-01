import SwiftUI
import UIKit

// Values mirror the Expense Tracker design system (tokens.json). Change them there first.

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    /// A colour that switches with the light and dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

enum Palette {
    static let bg = Color(light: 0xFFFFFF, dark: 0x0B0B0C)
    static let surface = Color(light: 0xF7F7F7, dark: 0x17171A)
    static let surfaceRaised = Color(light: 0xFFFFFF, dark: 0x222226)
    static let hairline = Color(light: 0xE6E6E6, dark: 0x2C2C31)
    static let ink = Color(light: 0x0B0B0C, dark: 0xF5F5F6)
    static let inkSecondary = Color(light: 0x6B6B6B, dark: 0xA3A3AA)
    static let inkTertiary = Color(light: 0x8A8A8A, dark: 0x6E6E75)
    static let action = Color(light: 0x0B0B0C, dark: 0xF5F5F6)
    static let onAction = Color(light: 0xFFFFFF, dark: 0x0B0B0C)
    static let chip = Color(light: 0xF1F1F1, dark: 0x26262B)
    static let heroFrom = Color(light: 0x6A6A73, dark: 0x46464F)
    static let heroTo = Color(light: 0x1C1C20, dark: 0x131316)
    static let onHero = Color.white
    static let income = Color(light: 0x1A9A66, dark: 0x2FB67C)
    static let onIncome = Color(light: 0xFFFFFF, dark: 0x04210F)
    static let incomeText = Color(light: 0x0F7F53, dark: 0x4CD69A)
    static let danger = Color(light: 0xC62828, dark: 0xFF8A80)
    static let review = Color(light: 0x8A5A00, dark: 0xF2B84B)
    static let focus = Color(light: 0x3D4BD8, dark: 0x8F9BFF)
    static let scrim = Color(light: 0x000000, dark: 0x000000).opacity(0.2)
}

/// Group identity colours. A group stores the key, not the colour.
enum GroupPalette {
    static let keys = ["orange", "indigo", "teal", "charcoal", "rose", "amber", "sky", "violet", "moss"]

    static func color(_ key: String) -> Color {
        switch key {
        case "orange": return Color(light: 0xD9701F, dark: 0xD9701F)
        case "indigo": return Color(light: 0x4455DD, dark: 0x4455DD)
        case "teal": return Color(light: 0x2E8F80, dark: 0x2E8F80)
        case "charcoal": return Color(light: 0x25252B, dark: 0x6B6B78)
        case "rose": return Color(light: 0xCF4560, dark: 0xCF4560)
        case "amber": return Color(light: 0xA87400, dark: 0xA87400)
        case "sky": return Color(light: 0x2F7FC4, dark: 0x2F7FC4)
        case "violet": return Color(light: 0x7B52D6, dark: 0x7B52D6)
        case "moss": return Color(light: 0x5C8A2E, dark: 0x5C8A2E)
        default: return Color(light: 0x25252B, dark: 0x6B6B78)
        }
    }

    static func label(_ key: String) -> String { key.capitalized }

    /// SF Symbols offered when creating a group.
    static let symbols = [
        "fork.knife", "car.fill", "gift.fill", "cart.fill", "bolt.fill", "house.fill",
        "heart.fill", "bag.fill", "airplane", "book.fill", "gamecontroller.fill", "tram.fill",
        "briefcase.fill", "laptopcomputer", "banknote.fill", "arrow.uturn.backward", "tag.fill", "cross.case.fill"
    ]
}

enum Space {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s12: CGFloat = 48
    /// Height of buttons and diameter of icon circles (44 pt tap target).
    static let control: CGFloat = 44
    static let glyph: CGFloat = 20
}

enum Radius {
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 32
}
