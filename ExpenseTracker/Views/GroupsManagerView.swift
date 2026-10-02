import SwiftUI
import SwiftData
import ExpenseCore

/// Add, edit, reorder and delete the groups of one side (expenses or income).
struct GroupsManagerView: View {
    let kind: TransactionKind
    @Environment(\.modelContext) private var context
    @Query(sort: \TxGroup.sortOrder) private var allGroups: [TxGroup]
    @State private var editing: TxGroup?
    @State private var adding = false

    private var groups: [TxGroup] { allGroups.filter { $0.kind == kind } }
    private var title: String { kind == .debit ? "Expense groups" : "Income groups" }

    var body: some View {
        List {
            if groups.isEmpty {
                EmptyNote(text: "No groups yet. Tap Add group to create one.")
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            ForEach(groups) { group in
                Button { editing = group } label: {
                    DSRow(
                        icon: IconDisc(symbol: group.symbol, color: GroupPalette.color(group.colorKey)),
                        title: group.name,
                        subtitle: "\(group.entries.count) \(group.entries.count == 1 ? "entry" : "entries")"
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: Space.s1 + 2, leading: Space.s4, bottom: Space.s1 + 2, trailing: Space.s4))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                for index in offsets { context.delete(groups[index]) }
                try? context.save()
                Task { @MainActor in Notifier.refreshCategory() }
            }
            .onMove { source, destination in
                var reordered = groups
                reordered.move(fromOffsets: source, toOffset: destination)
                for (index, group) in reordered.enumerated() { group.sortOrder = index }
                try? context.save()
                Task { @MainActor in Notifier.refreshCategory() }
            }

            Text("Deleting a group keeps its entries and marks them \(kind == .debit ? "Uncategorized" : "Untagged").")
                .ds(.caption)
                .foregroundStyle(Palette.inkSecondary)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button { adding = true } label: { Label("Add group", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $adding) {
            GroupEditSheet(group: nil, kind: kind, nextOrder: groups.count)
        }
        .sheet(item: $editing) { group in
            GroupEditSheet(group: group, kind: kind, nextOrder: groups.count)
        }
    }
}

struct GroupEditSheet: View {
    let group: TxGroup?
    let kind: TransactionKind
    let nextOrder: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var colorKey = GroupPalette.keys[0]
    @State private var symbol = GroupPalette.symbols[0]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                SheetHeader(title: group == nil ? "Add group" : "Edit group") { dismiss() }

                HStack {
                    Spacer()
                    IconDisc(symbol: symbol, color: GroupPalette.color(colorKey))
                    Spacer()
                }

                DSTextField(placeholder: kind == .debit ? "Group name, like Food" : "Group name, like Salary", text: $name)

                VStack(alignment: .leading, spacing: Space.s3) {
                    Text("Colour").ds(.title).foregroundStyle(Palette.ink)
                    FlowLayout(spacing: Space.s3) {
                        ForEach(GroupPalette.keys, id: \.self) { key in
                            Button { colorKey = key } label: {
                                Circle()
                                    .fill(GroupPalette.color(key))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if colorKey == key {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay(Circle().stroke(Palette.focus, lineWidth: colorKey == key ? 2 : 0).padding(-4))
                            }
                            .accessibilityLabel(GroupPalette.label(key))
                            .accessibilityAddTraits(colorKey == key ? .isSelected : [])
                        }
                    }
                    .padding(4)
                }

                VStack(alignment: .leading, spacing: Space.s3) {
                    Text("Icon").ds(.title).foregroundStyle(Palette.ink)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s2), count: 6), spacing: Space.s2) {
                        ForEach(GroupPalette.symbols, id: \.self) { item in
                            Button { symbol = item } label: {
                                Image(systemName: item)
                                    .font(.system(size: Space.glyph, weight: .semibold))
                                    .foregroundStyle(symbol == item ? Palette.onAction : Palette.ink)
                                    .frame(width: Space.control, height: Space.control)
                                    .background(symbol == item ? Palette.action : Palette.chip, in: Circle())
                            }
                            .accessibilityLabel(item)
                        }
                    }
                }

                Button("Save", action: save)
                    .buttonStyle(.pillStyle(.primary, fullWidth: true))
                    .disabled(trimmedName.isEmpty)
            }
            .padding(Space.s4)
        }
        .background(Palette.bg)
        .presentationDetents([.large])
        .presentationCornerRadius(Radius.xl)
        .onAppear {
            if let group {
                name = group.name
                colorKey = group.colorKey
                symbol = group.symbol
            }
        }
    }

    private func save() {
        if let group {
            group.name = trimmedName
            group.colorKey = colorKey
            group.symbol = symbol
        } else {
            context.insert(TxGroup(name: trimmedName, kind: kind, colorKey: colorKey, symbol: symbol, sortOrder: nextOrder))
        }
        try? context.save()
        Task { @MainActor in Notifier.refreshCategory() }
        dismiss()
    }
}
