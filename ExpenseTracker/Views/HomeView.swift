import SwiftUI
import SwiftData
import ExpenseCore

struct HomeView: View {
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \TxGroup.sortOrder) private var allGroups: [TxGroup]
    @AppStorage(SettingsKey.periodStartDay) private var startDay = 1
    @AppStorage(SettingsKey.customStart) private var customStart = 0.0
    @AppStorage(SettingsKey.customEnd) private var customEnd = 0.0

    @State private var showAdd = false
    @State private var showAll = false
    @State private var selected: LedgerEntry?

    private var period: BillingPeriod { currentPeriod(startDay: startDay, customStart: customStart, customEnd: customEnd) }
    private var expenses: [LedgerEntry] { entries.filter { $0.kind == .debit && period.contains($0.date) } }
    private var groups: [TxGroup] { allGroups.filter { $0.kind == .debit } }
    private var total: Decimal { expenses.reduce(0) { $0 + $1.amount } }

    private func groupTotal(_ group: TxGroup?) -> Decimal {
        expenses.filter { $0.group?.id == group?.id }.reduce(0) { $0 + $1.amount }
    }

    private var uncategorizedTotal: Decimal {
        expenses.filter { $0.group == nil }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.s8) {
                        totalBlock
                        groupsSection
                        activitySection
                    }
                    .padding(.horizontal, Space.s4)
                    .padding(.top, Space.s4)
                    .padding(.bottom, 110)
                }
                actionBar
            }
            .background(Palette.bg)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAll) {
                ActivityListView(title: "Expenses", kind: .debit)
            }
            .sheet(isPresented: $showAdd) { AddEntrySheet(kind: .debit) }
            .sheet(item: $selected) { EntryDetailSheet(entry: $0) }
        }
    }

    private var totalBlock: some View {
        VStack(alignment: .leading, spacing: Space.s1) {
            Text("Total spent · \(period.label())")
                .ds(.caption)
                .foregroundStyle(Palette.inkSecondary)
            Text(AppFormat.money(total))
                .ds(.amountDisplay)
                .tabularFigures()
                .foregroundStyle(Palette.danger)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }

    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            SectionHeader(title: "Expense groups", count: groups.count)
            if groups.isEmpty && uncategorizedTotal == 0 {
                EmptyNote(text: "No groups yet. Add some in Settings.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Space.s3), GridItem(.flexible(), spacing: Space.s3)], spacing: Space.s3) {
                    ForEach(groups) { group in
                        GroupTile(
                            symbol: group.symbol,
                            color: GroupPalette.color(group.colorKey),
                            name: group.name,
                            total: AppFormat.money(groupTotal(group))
                        )
                    }
                    if uncategorizedTotal > 0 {
                        GroupTile(
                            symbol: "questionmark",
                            color: GroupPalette.color("charcoal"),
                            name: "Uncategorized",
                            total: AppFormat.money(uncategorizedTotal)
                        )
                    }
                }
            }
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            SectionHeader(title: "Activity", actionTitle: expenses.isEmpty ? nil : "View all") { showAll = true }
            if expenses.isEmpty {
                EmptyNote(text: "No expenses yet. They appear here when your bank sends an alert.")
            } else {
                VStack(spacing: Space.s3) {
                    ForEach(expenses.prefix(6)) { entry in
                        Button { selected = entry } label: { EntryRow(entry: entry) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var actionBar: some View {
        Button("Add expense") { showAdd = true }
            .buttonStyle(.pillStyle(.primary, fullWidth: true))
        .padding(.horizontal, Space.s4)
        .padding(.top, Space.s3)
        .padding(.bottom, Space.s2)
        .background(
            LinearGradient(colors: [Palette.bg.opacity(0), Palette.bg], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35))
        )
    }
}
