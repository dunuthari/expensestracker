import SwiftUI
import SwiftData
import ExpenseCore

struct IncomeView: View {
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \TxGroup.sortOrder) private var allGroups: [TxGroup]
    @AppStorage(SettingsKey.periodStartDay) private var startDay = 1
    @AppStorage(SettingsKey.customStart) private var customStart = 0.0
    @AppStorage(SettingsKey.customEnd) private var customEnd = 0.0

    @State private var showAdd = false
    @State private var showAll = false
    @State private var selected: LedgerEntry?

    private var period: BillingPeriod { currentPeriod(startDay: startDay, customStart: customStart, customEnd: customEnd) }
    private var credits: [LedgerEntry] { entries.filter { $0.kind == .credit && period.contains($0.date) } }
    private var groups: [TxGroup] { allGroups.filter { $0.kind == .credit } }
    private var total: Decimal { credits.reduce(0) { $0 + $1.amount } }
    private var untaggedCount: Int { credits.filter { $0.group == nil }.count }

    private func groupTotal(_ group: TxGroup) -> Decimal {
        credits.filter { $0.group?.id == group.id }.reduce(0) { $0 + $1.amount }
    }

    private var untaggedTotal: Decimal {
        credits.filter { $0.group == nil }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Space.s8) {
                        VStack(alignment: .leading, spacing: Space.s1) {
                            Text("Income · \(period.label())")
                                .ds(.caption)
                                .foregroundStyle(Palette.inkSecondary)
                            Text(AppFormat.money(total, signed: total > 0))
                                .ds(.amountDisplay)
                                .tabularFigures()
                                .foregroundStyle(total > 0 ? Palette.incomeText : Palette.ink)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }

                        VStack(alignment: .leading, spacing: Space.s3) {
                            SectionHeader(title: "Income groups", count: groups.count)
                            if groups.isEmpty && untaggedTotal == 0 {
                                EmptyNote(text: "No income groups yet. Add some in Settings.")
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
                                    if untaggedTotal > 0 {
                                        GroupTile(
                                            symbol: "questionmark",
                                            color: GroupPalette.color("charcoal"),
                                            name: "Untagged",
                                            total: AppFormat.money(untaggedTotal)
                                        )
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: Space.s3) {
                            SectionHeader(title: "Credits", actionTitle: credits.isEmpty ? nil : "View all") { showAll = true }
                            if untaggedCount > 0 {
                                Text("\(untaggedCount) untagged. Tap a credit to pick a group.")
                                    .ds(.caption)
                                    .foregroundStyle(Palette.inkSecondary)
                            }
                            if credits.isEmpty {
                                EmptyNote(text: "No income yet. Credits from your bank are saved here without a notification.")
                            } else {
                                VStack(spacing: Space.s3) {
                                    ForEach(credits.prefix(8)) { entry in
                                        Button { selected = entry } label: { EntryRow(entry: entry) }
                                            .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Space.s4)
                    .padding(.top, Space.s4)
                    .padding(.bottom, 110)
                }

                Button("Add income") { showAdd = true }
                    .buttonStyle(.pillStyle(.primary, fullWidth: true))
                    .padding(.horizontal, Space.s4)
                    .padding(.top, Space.s3)
                    .padding(.bottom, Space.s2)
                    .background(
                        LinearGradient(colors: [Palette.bg.opacity(0), Palette.bg], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35))
                    )
            }
            .background(Palette.bg)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showAll) {
                ActivityListView(title: "Income", kind: .credit)
            }
            .sheet(isPresented: $showAdd) { AddEntrySheet(kind: .credit) }
            .sheet(item: $selected) { EntryDetailSheet(entry: $0) }
        }
    }
}
