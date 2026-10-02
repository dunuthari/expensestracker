import SwiftUI
import SwiftData

/// Step-by-step help for the one-time Shortcuts automation, plus test buttons.
struct SetupGuideView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL
    @State private var status: String?

    private let steps: [(String, String)] = [
        ("Open Shortcuts", "Go to the Automation tab, tap New Automation, then choose Message."),
        ("Pick your bank", "Under Message From, choose your bank's sender. While testing, you can use Message Contains: HNB SMS ALERT."),
        ("Run Immediately", "Choose Run Immediately so it works without a tap, then tap Next."),
        ("Add the action", "Tap New Blank Automation, search for Log Expense from Message and add it. Set Message to Shortcut Input."),
        ("Quiet the banner", "Open the automation and turn off Notify When Run, so only this app's notification appears."),
        ("Allow notifications", "Allow notifications for this app when asked, or turn them on in Settings.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.s8) {
                Text("iOS doesn't let apps read your messages. A Shortcuts automation passes each bank message to this app. You set it up once, in about two minutes.")
                    .ds(.body)
                    .foregroundStyle(Palette.inkSecondary)

                Button("Open Shortcuts") {
                    if let url = URL(string: "shortcuts://") { openURL(url) }
                }
                .buttonStyle(.pillStyle(.primary, fullWidth: true))

                VStack(alignment: .leading, spacing: Space.s3) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: Space.s4) {
                            Text("\(index + 1)")
                                .ds(.bodyStrong)
                                .tabularFigures()
                                .foregroundStyle(Palette.onAction)
                                .frame(width: 28, height: 28)
                                .background(Palette.action, in: Circle())
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: Space.s1) {
                                Text(step.0).ds(.rowTitle).foregroundStyle(Palette.ink)
                                Text(step.1).ds(.body).foregroundStyle(Palette.inkSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Space.s4)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                    }
                }

                VStack(alignment: .leading, spacing: Space.s3) {
                    Text("Test it").ds(.title).foregroundStyle(Palette.ink)
                    Text("Adds a sample to your data that you can delete from Activity. A debit shows a notification. A credit stays silent.")
                        .ds(.body)
                        .foregroundStyle(Palette.inkSecondary)
                    HStack(spacing: Space.s3) {
                        Button("Test a debit") { Task { await run(SampleMessages.debit()) } }
                            .buttonStyle(.pillStyle(.primary, fullWidth: true))
                        Button("Test a credit") { Task { await run(SampleMessages.credit()) } }
                            .buttonStyle(.pillStyle(.secondary, fullWidth: true))
                    }
                    if let status {
                        Text(status).ds(.body).foregroundStyle(Palette.ink)
                    }
                }
            }
            .padding(Space.s4)
        }
        .background(Palette.bg)
        .navigationTitle("Shortcut setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func run(_ text: String) async {
        switch await Ingestor.ingest(text, context: context) {
        case .recorded(let entry):
            status = entry.kind == .debit
                ? "Saved \(AppFormat.money(entry.amount)). A notification should appear."
                : "Saved \(AppFormat.money(entry.amount, signed: true)) as income. No notification, as expected."
        case .duplicate:
            status = "That sample was skipped because Ignore repeated messages is on."
        case .unrecognized:
            status = "The sample couldn't be read. It's in Inbox."
        }
    }
}
