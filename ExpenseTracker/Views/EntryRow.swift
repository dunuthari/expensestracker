import SwiftData
import SwiftUI
import ExpenseCore

/// One expense or income as a list row.
struct EntryRow: View {
    let entry: LedgerEntry

    var body: some View {
        let isIncome = entry.kind == .credit
        let groupName = entry.group?.name ?? (isIncome ? "Untagged" : "Uncategorized")
        DSRow(
            icon: IconDisc(
                symbol: entry.group?.symbol ?? (isIncome ? "arrow.down" : "questionmark"),
                color: entry.group.map { GroupPalette.color($0.colorKey) } ?? Palette.action,
                tintedByInk: entry.group == nil,
                badge: isIncome
            ),
            title: entry.merchant,
            subtitle: "\(groupName) · \(AppFormat.day(entry.date))",
            value: AppFormat.money(entry.amount, signed: isIncome),
            valueIsIncome: isIncome
        )
    }
}

/// A scrolling list of entries with swipe to delete, used by "View all".
struct ActivityListView: View {
    let title: String
    let kind: TransactionKind
    @Environment(\.modelContext) private var context
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @State private var selected: LedgerEntry?

    private var filtered: [LedgerEntry] { entries.filter { $0.kind == kind } }

    var body: some View {
        List {
            ForEach(filtered) { entry in
                Button { selected = entry } label: { EntryRow(entry: entry) }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: Space.s1 + 2, leading: Space.s4, bottom: Space.s1 + 2, trailing: Space.s4))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                for index in offsets { context.delete(filtered[index]) }
                try? context.save()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if filtered.isEmpty {
                EmptyNote(text: kind == .debit ? "No expenses yet." : "No income yet.").padding(Space.s4)
            }
        }
        .sheet(item: $selected) { EntryDetailSheet(entry: $0) }
    }
}
