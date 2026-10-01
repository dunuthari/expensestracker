import SwiftUI
import UIKit

/// The type scale from the design system. Sizes follow Dynamic Type through UIFontMetrics.
enum DSTextStyle {
    case amountEntry, amountDisplay, amountCard
    case titleLg, title
    case rowTitle, rowValue, body, bodyStrong, caption, footnote
    case button, chip, link

    private var spec: (size: CGFloat, weight: Font.Weight, tracking: CGFloat, relativeTo: UIFont.TextStyle) {
        switch self {
        case .amountEntry: return (64, .bold, -2, .largeTitle)
        case .amountDisplay: return (48, .bold, -1.5, .largeTitle)
        case .amountCard: return (28, .bold, -0.6, .title1)
        case .titleLg: return (20, .semibold, -0.3, .title3)
        case .title: return (18, .semibold, -0.2, .headline)
        case .rowTitle: return (18, .semibold, -0.2, .headline)
        case .rowValue: return (18, .semibold, -0.2, .headline)
        case .body: return (16, .regular, 0, .body)
        case .bodyStrong: return (16, .semibold, 0, .body)
        case .caption: return (14, .regular, 0, .caption1)
        case .footnote: return (12, .regular, 0, .footnote)
        case .button: return (18, .semibold, -0.2, .headline)
        case .chip: return (16, .semibold, 0, .callout)
        case .link: return (16, .semibold, 0, .callout)
        }
    }

    var font: Font {
        let scaled = UIFontMetrics(forTextStyle: spec.relativeTo).scaledValue(for: spec.size)
        return .system(size: scaled, weight: spec.weight)
    }

    var tracking: CGFloat { spec.tracking }
}

private struct DSTextModifier: ViewModifier {
    let style: DSTextStyle
    func body(content: Content) -> some View {
        content.font(style.font).tracking(style.tracking)
    }
}

extension View {
    /// Applies a design-system text style.
    func ds(_ style: DSTextStyle) -> some View {
        modifier(DSTextModifier(style: style))
    }

    /// Tabular figures, so columns of amounts line up.
    func tabularFigures() -> some View {
        monospacedDigit()
    }
}
