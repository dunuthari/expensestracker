import SwiftUI

// MARK: - Button

/// Pill button. Primary is the black (white in dark mode) action; secondary is the quiet grey one.
struct PillButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    var kind: Kind = .primary
    var fullWidth = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .ds(.button)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, Space.s6)
            .frame(height: Space.control)
            .background(background, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }

    private var background: Color {
        guard isEnabled else { return Palette.chip }
        return kind == .primary ? Palette.action : Palette.chip
    }

    private var foreground: Color {
        guard isEnabled else { return Palette.inkTertiary }
        return kind == .primary ? Palette.onAction : Palette.ink
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
    static var pillSecondary: PillButtonStyle { PillButtonStyle(kind: .secondary) }
    static func pillStyle(_ kind: PillButtonStyle.Kind = .primary, fullWidth: Bool = false) -> PillButtonStyle {
        PillButtonStyle(kind: kind, fullWidth: fullWidth)
    }
}

/// Round 44 pt floating button.
struct IconButton: View {
    let symbol: String
    let label: String
    var plain = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: Space.glyph, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(width: Space.control, height: Space.control)
                .background(plain ? Color.clear : Palette.surfaceRaised, in: Circle())
                .shadow(color: .black.opacity(plain ? 0 : 0.06), radius: 12, y: 4)
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Icon disc

/// A 44 pt coloured disc with a white glyph. Credits add a small green plus badge.
struct IconDisc: View {
    let symbol: String
    var color: Color
    var tintedByInk = false
    var badge = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: Space.control, height: Space.control)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: Space.glyph, weight: .semibold))
                    .foregroundStyle(tintedByInk ? Palette.onAction : Color.white)
            }
            .overlay(alignment: .topLeading) {
                if badge {
                    Circle()
                        .fill(Palette.income)
                        .frame(width: 20, height: 20)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(Palette.onIncome)
                        }
                        .overlay(Circle().stroke(Palette.surface, lineWidth: 2))
                        .offset(x: -4, y: -4)
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Rows and tiles

struct DSRow: View {
    let icon: IconDisc
    let title: String
    var subtitle: String?
    var subtitleIsReview = false
    var value: String?
    var valueIsIncome = false

    var body: some View {
        HStack(spacing: Space.s4) {
            icon
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .ds(.rowTitle)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .ds(.body)
                        .foregroundStyle(subtitleIsReview ? Palette.review : Palette.inkSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: Space.s2)
            if let value {
                Text(value)
                    .ds(.rowValue)
                    .tabularFigures()
                    .foregroundStyle(valueIsIncome ? Palette.incomeText : Palette.ink)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(1)
            }
        }
        .padding(Space.s4)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .contentShape(Rectangle())
    }
}

struct GroupTile: View {
    let symbol: String
    let color: Color
    let name: String
    let total: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            IconDisc(symbol: symbol, color: color)
            VStack(alignment: .leading, spacing: 0) {
                Text(name).ds(.rowTitle).foregroundStyle(Palette.ink).lineLimit(1)
                Text(total).ds(.body).tabularFigures().foregroundStyle(Palette.inkSecondary).lineLimit(1).minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.s4)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct SectionHeader: View {
    let title: String
    var count: Int?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: Space.s3) {
            Text(title).ds(.title).foregroundStyle(Palette.ink)
            if let count {
                Text("\(count)")
                    .ds(.caption)
                    .fontWeight(.semibold)
                    .tabularFigures()
                    .foregroundStyle(Palette.ink)
                    .frame(minWidth: 28, minHeight: 28)
                    .padding(.horizontal, Space.s2)
                    .background(Palette.chip, in: Capsule())
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .ds(.link)
                    .foregroundStyle(Palette.ink)
            }
        }
    }
}

struct Chip: View {
    let title: String
    var isSelected = false
    var dotColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.s2) {
                if let dotColor {
                    Circle().fill(dotColor).frame(width: 10, height: 10)
                }
                Text(title).ds(.chip).lineLimit(1)
            }
            .foregroundStyle(isSelected ? Palette.onAction : Palette.ink)
            .padding(.horizontal, Space.s4)
            .frame(height: Space.control)
            .background(isSelected ? Palette.action : Palette.chip, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Hero card

struct HeroCard: View {
    let label: String
    let total: String
    var leftLabel: String?
    var leftValue: String?
    var rightLabel: String?
    var rightValue: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s4) {
            VStack(alignment: .leading, spacing: 0) {
                Text(label).ds(.caption).foregroundStyle(Palette.onHero.opacity(0.92))
                Text(total).ds(.amountCard).tabularFigures().foregroundStyle(Palette.onHero)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            if let leftLabel, let leftValue, let rightLabel, let rightValue {
                Rectangle().fill(Color.white.opacity(0.24)).frame(height: 1)
                HStack(alignment: .top, spacing: Space.s4) {
                    stat(leftLabel, leftValue)
                    stat(rightLabel, rightValue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.s4)
        .background(
            LinearGradient(colors: [Palette.heroFrom, Palette.heroTo], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).ds(.caption).foregroundStyle(Palette.onHero.opacity(0.92))
            Text(value).ds(.rowValue).tabularFigures().foregroundStyle(Palette.onHero)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sheet header

struct SheetHeader: View {
    let title: String
    var subtitle: String?
    let close: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Text(title).ds(.titleLg).foregroundStyle(Palette.ink)
                if let subtitle {
                    Text(subtitle).ds(.body).foregroundStyle(Palette.inkSecondary).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Space.control)
            IconButton(symbol: "xmark", label: "Close", action: close)
        }
    }
}

// MARK: - Misc

struct EmptyNote: View {
    let text: String
    var body: some View {
        Text(text)
            .ds(.body)
            .foregroundStyle(Palette.inkSecondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.s4)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
    }
}

struct DSTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .ds(.body)
            .keyboardType(keyboard)
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, Space.s4)
            .frame(minHeight: Space.control + 4)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
