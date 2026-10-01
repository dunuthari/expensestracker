import SwiftUI
import SwiftData
import Charts
import ExpenseCore

struct ReportView: View {
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \TxGroup.sortOrder) private var allGroups: [TxGroup]
    @AppStorage(SettingsKey.periodStartDay) private var startDay = 1
    @State private var offset = 0

    private var period: BillingPeriod {
        BillingPeriod.containing(Date(), startDay: startDay).shifted(by: offset)
    }
    private var inPeriod: [LedgerEntry] { entries.filter { period.contains($0.date) } }
    private var expenses: [LedgerEntry] { inPeriod.filter { $0.kind == .debit } }
    private var income: [LedgerEntry] { inPeriod.filter { $0.kind == .credit } }
    private var expenseTotal: Decimal { expenses.reduce(0) { $0 + $1.amount } }
    private var incomeTotal: Decimal { income.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s8) {
                    periodPicker
                    HeroCard(
                        label: "Expenses · \(period.label())",
                        total: AppFormat.money(expenseTotal),
                        leftLabel: "Income",
                        leftValue: AppFormat.money(incomeTotal, signed: incomeTotal > 0),
                        rightLabel: "Net",
                        rightValue: AppFormat.money(incomeTotal - expenseTotal)
                    )
                    GroupBreakdown(
                        title: "Expenses by group",
                        emptyText: "No expenses in this period.",
                        ungroupedName: "Uncategorized",
                        entries: expenses,
                        groups: allGroups.filter { $0.kind == .debit },
                        isIncome: false
                    )
                    GroupBreakdown(
                        title: "Income by group",
                        emptyText: "No income in this period.",
                        ungroupedName: "Untagged",
                        entries: income,
                        groups: allGroups.filter { $0.kind == .credit },
                        isIncome: true
                    )
                }
                .padding(Space.s4)
            }
            .background(Palette.bg)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var periodPicker: some View {
        HStack {
            IconButton(symbol: "chevron.left", label: "Previous period") { offset -= 1 }
            Spacer()
            VStack(spacing: 0) {
                Text(period.label()).ds(.titleLg).foregroundStyle(Palette.ink)
                Text(offset == 0 ? "This period" : "\(abs(offset)) period\(abs(offset) == 1 ? "" : "s") ago")
                    .ds(.caption)
                    .foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            IconButton(symbol: "chevron.right", label: "Next period") { offset += 1 }
                .disabled(offset >= 0)
                .opacity(offset >= 0 ? 0.4 : 1)
        }
    }
}

/// A donut chart plus a legend of totals per group. Each slice is named in text, never by colour alone.
struct GroupBreakdown: View {
    let title: String
    let emptyText: String
    let ungroupedName: String
    let entries: [LedgerEntry]
    let groups: [TxGroup]
    let isIncome: Bool

    private struct Slice: Identifiable {
        let id: String
        let name: String
        let color: Color
        let total: Decimal
        let share: Double
    }

    private var slices: [Slice] {
        let items = entries.map { ReportItem(groupID: $0.group?.id.uuidString, amount: $0.amount) }
        let all = Report.totals(items)
        let sum = Report.sum(items)
        return all.map { total in
            let group = groups.first { $0.id.uuidString == total.id }
            return Slice(
                id: total.id,
                name: group?.name ?? ungroupedName,
                color: group.map { GroupPalette.color($0.colorKey) } ?? GroupPalette.color("charcoal"),
                total: total.total,
                share: Report.share(total.total, of: sum)
            )
        }
    }

    var body: some View {
        let slices = self.slices
        VStack(alignment: .leading, spacing: Space.s3) {
            SectionHeader(title: title)
            if slices.isEmpty {
                EmptyNote(text: emptyText)
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: slice.total).doubleValue),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(slice.color)
                }
                .chartLegend(.hidden)
                .frame(height: 220)
                .overlay {
                    VStack(spacing: 0) {
                        Text("Total").ds(.caption).foregroundStyle(Palette.inkSecondary)
                        Text(AppFormat.money(Report.sum(entries.map { ReportItem(groupID: nil, amount: $0.amount) }), signed: isIncome))
                            .ds(.title)
                            .tabularFigures()
                            .foregroundStyle(isIncome ? Palette.incomeText : Palette.ink)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 56)
                }
                .accessibilityLabel(title)

                VStack(spacing: 0) {
                    ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                        HStack(spacing: Space.s3) {
                            Circle().fill(slice.color).frame(width: 12, height: 12)
                            Text(slice.name).ds(.bodyStrong).foregroundStyle(Palette.ink).lineLimit(1)
                            Spacer(minLength: Space.s2)
                            Text("\(Int((slice.share * 100).rounded()))%")
                                .ds(.caption)
                                .tabularFigures()
                                .foregroundStyle(Palette.inkSecondary)
                            Text(AppFormat.money(slice.total, signed: isIncome))
                                .ds(.rowValue)
                                .tabularFigures()
                                .foregroundStyle(isIncome ? Palette.incomeText : Palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.vertical, Space.s3)
                        if index < slices.count - 1 {
                            Rectangle().fill(Palette.hairline).frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, Space.s4)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            }
        }
    }
}
