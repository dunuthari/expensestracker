import SwiftUI
import SwiftData
import ExpenseCore

// MARK: - Entry detail

/// Change the group, add a reason, or delete one entry.
struct EntryDetailSheet: View {
    @Bindable var entry: LedgerEntry
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TxGroup.sortOrder) private var allGroups: [TxGroup]
    @State private var confirmDelete = false

    private var groups: [TxGroup] { allGroups.filter { $0.kind == entry.kind } }
    private var isIncome: Bool { entry.kind == .credit }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                SheetHeader(title: isIncome ? "Income" : "Expense", subtitle: AppFormat.dayAndTime(entry.date)) { dismiss() }

                VStack(spacing: Space.s1) {
                    Text(AppFormat.money(entry.amount, signed: isIncome))
                        .ds(.amountCard)
                        .tabularFigures()
                        .foregroundStyle(isIncome ? Palette.incomeText : Palette.ink)
                    Text([entry.merchant, entry.channel].filter { !$0.isEmpty }.joined(separator: " · "))
                        .ds(.body)
                        .foregroundStyle(Palette.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: Space.s3) {
                    Text(isIncome ? "Income group" : "Expense group").ds(.title).foregroundStyle(Palette.ink)
                    if groups.isEmpty {
                        EmptyNote(text: "No groups yet. Add one in Settings.")
                    } else {
                        FlowLayout(spacing: Space.s2) {
                            ForEach(groups) { group in
                                Chip(
                                    title: group.name,
                                    isSelected: entry.group?.id == group.id,
                                    dotColor: GroupPalette.color(group.colorKey)
                                ) {
                                    entry.group = (entry.group?.id == group.id) ? nil : group
                                    try? context.save()
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Space.s3) {
                    Text("Reason").ds(.title).foregroundStyle(Palette.ink)
                    DSTextField(placeholder: "Add a reason", text: $entry.note)
                }

                if !entry.rawText.isEmpty {
                    DisclosureGroup {
                        Text(entry.rawText)
                            .ds(.caption)
                            .foregroundStyle(Palette.inkSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, Space.s2)
                            .textSelection(.enabled)
                    } label: {
                        Text("Original message").ds(.bodyStrong).foregroundStyle(Palette.ink)
                    }
                }

                Button {
                    confirmDelete = true
                } label: {
                    Label("Delete", systemImage: "trash")
                        .ds(.button)
                        .foregroundStyle(Palette.danger)
                        .frame(maxWidth: .infinity, minHeight: Space.control)
                        .background(Palette.chip, in: Capsule())
                }
                .confirmationDialog("Delete this entry?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        context.delete(entry)
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .padding(Space.s4)
        }
        .background(Palette.bg)
        .onDisappear { try? context.save() }
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.xl)
    }
}

// MARK: - Add manually

/// Enter an expense or income by hand.
struct AddEntrySheet: View {
    let kind: TransactionKind
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TxGroup.sortOrder) private var allGroups: [TxGroup]
    @State private var amountText = ""
    @State private var merchant = ""
    @State private var date = Date()
    @State private var group: TxGroup?

    private var isIncome: Bool { kind == .credit }
    private var groups: [TxGroup] { allGroups.filter { $0.kind == kind } }
    private var amount: Decimal? {
        let value = Decimal(string: amountText.replacingOccurrences(of: ",", with: ""), locale: Locale(identifier: "en_US_POSIX"))
        guard let value, value > 0 else { return nil }
        return value
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                SheetHeader(title: isIncome ? "Add income" : "Add expense") { dismiss() }

                HStack(alignment: .top, spacing: Space.s1) {
                    Text(AppFormat.currency)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Palette.inkSecondary)
                        .padding(.top, 8)
                    TextField("0", text: $amountText)
                        .ds(.amountEntry)
                        .tabularFigures()
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .fixedSize()
                        .foregroundStyle(Palette.ink)
                }
                .frame(maxWidth: .infinity)

                DSTextField(placeholder: isIncome ? "Reason" : "Merchant or reason", text: $merchant)

                DatePicker("Date", selection: $date)
                    .ds(.body)
                    .foregroundStyle(Palette.ink)

                VStack(alignment: .leading, spacing: Space.s3) {
                    Text(isIncome ? "Income group" : "Expense group").ds(.title).foregroundStyle(Palette.ink)
                    FlowLayout(spacing: Space.s2) {
                        ForEach(groups) { item in
                            Chip(
                                title: item.name,
                                isSelected: group?.id == item.id,
                                dotColor: GroupPalette.color(item.colorKey)
                            ) {
                                group = (group?.id == item.id) ? nil : item
                            }
                        }
                    }
                }

                Button("Save", action: save)
                    .buttonStyle(.pillStyle(.primary, fullWidth: true))
                    .disabled(amount == nil)
            }
            .padding(Space.s4)
        }
        .background(Palette.bg)
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.xl)
    }

    private func save() {
        guard let amount else { return }
        let name = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = LedgerEntry(
            kind: kind,
            amount: amount,
            currency: AppFormat.currency,
            merchant: name.isEmpty ? (isIncome ? "Income" : "Expense") : name,
            channel: "MANUAL",
            date: date,
            group: group
        )
        context.insert(entry)
        try? context.save()
        dismiss()
    }
}

// MARK: - Paste a message

/// Fallback when the Shortcuts automation did not run: paste the bank SMS here.
struct PasteMessageSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var status: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                SheetHeader(title: "Paste bank message") { dismiss() }

                TextEditor(text: $text)
                    .ds(.body)
                    .foregroundStyle(Palette.ink)
                    .scrollContentBackground(.hidden)
                    .padding(Space.s3)
                    .frame(minHeight: 180)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

                HStack(spacing: Space.s3) {
                    Button("Paste") { text = UIPasteboard.general.string ?? text }
                        .buttonStyle(.pillStyle(.secondary))
                    Button("Save") { Task { await save() } }
                        .buttonStyle(.pillStyle(.primary, fullWidth: true))
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let status {
                    Text(status).ds(.body).foregroundStyle(Palette.inkSecondary)
                }
            }
            .padding(Space.s4)
        }
        .background(Palette.bg)
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.xl)
    }

    private func save() async {
        let result = await Ingestor.ingest(text, context: context, notify: false)
        switch result {
        case .recorded:
            dismiss()
        case .duplicate:
            status = "This message is already saved."
        case .unrecognized:
            status = "We couldn't read this message. It's in Inbox under Needs review."
        }
    }
}
