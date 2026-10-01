import SwiftUI
import SwiftData
import ExpenseCore

/// Messages the parser could not read.
struct InboxView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UnparsedMessage.receivedAt, order: .reverse) private var messages: [UnparsedMessage]
    @State private var selected: UnparsedMessage?

    var body: some View {
        NavigationStack {
            List {
                if messages.isEmpty {
                    EmptyNote(text: "Nothing to review. Messages we can't read show up here.")
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(messages) { message in
                        Button { selected = message } label: {
                            DSRow(
                                icon: IconDisc(symbol: "questionmark", color: Palette.action, tintedByInk: true),
                                title: String(message.text.prefix(60)),
                                subtitle: "Needs review · \(AppFormat.day(message.receivedAt))",
                                subtitleIsReview: true
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: Space.s1 + 2, leading: Space.s4, bottom: Space.s1 + 2, trailing: Space.s4))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { offsets in
                        for index in offsets { context.delete(messages[index]) }
                        try? context.save()
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Palette.bg)
            .navigationTitle("Inbox")
            .sheet(item: $selected) { UnparsedSheet(message: $0) }
        }
    }
}

private struct UnparsedSheet: View {
    let message: UnparsedMessage
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var status: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s6) {
                SheetHeader(title: "Needs review", subtitle: AppFormat.dayAndTime(message.receivedAt)) { dismiss() }

                Text("We couldn't read this message. Try again, or dismiss it and add the expense by hand.")
                    .ds(.body)
                    .foregroundStyle(Palette.inkSecondary)

                Text(message.text)
                    .ds(.body)
                    .foregroundStyle(Palette.ink)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Space.s4)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

                if let status {
                    Text(status).ds(.body).foregroundStyle(Palette.review)
                }

                HStack(spacing: Space.s3) {
                    Button("Dismiss") {
                        context.delete(message)
                        try? context.save()
                        dismiss()
                    }
                    .buttonStyle(.pillStyle(.secondary))
                    Button("Try again") {
                        Task {
                            if await Ingestor.retry(message, context: context) {
                                dismiss()
                            } else {
                                status = "Still can't read it. Send this message to the developer to add support."
                            }
                        }
                    }
                    .buttonStyle(.pillStyle(.primary, fullWidth: true))
                }
            }
            .padding(Space.s4)
        }
        .background(Palette.bg)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(Radius.xl)
    }
}
