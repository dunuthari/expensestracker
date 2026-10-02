import SwiftUI
import SwiftData
import UserNotifications
import ExpenseCore

struct SettingsView: View {
    @AppStorage(SettingsKey.periodStartDay) private var startDay = 1
    @AppStorage(SettingsKey.customStart) private var customStart = 0.0
    @AppStorage(SettingsKey.customEnd) private var customEnd = 0.0
    @State private var draftStart = Date()
    @State private var draftEnd = Date()
    @AppStorage(SettingsKey.lastMessageAt) private var lastMessageAt = 0.0
    @AppStorage(SettingsKey.ignoreDuplicates) private var ignoreDuplicates = false
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    private var period: BillingPeriod { currentPeriod(startDay: startDay, customStart: customStart, customEnd: customEnd) }

    private var endBeforeStart: Bool {
        Calendar.current.startOfDay(for: draftEnd) < Calendar.current.startOfDay(for: draftStart)
    }

    private var periodMessage: String {
        if endBeforeStart { return "The end date can't be before the start date." }
        return period.isCustom
            ? "Custom period: \(period.label())."
            : "Current period: \(period.label()). It follows the calendar month until you set dates."
    }

    private func applyDates() {
        guard !endBeforeStart else { return }
        customStart = Calendar.current.startOfDay(for: draftStart).timeIntervalSince1970
        customEnd = Calendar.current.startOfDay(for: draftEnd).timeIntervalSince1970
    }

    private func dateRow(_ title: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(title).ds(.rowTitle).foregroundStyle(Palette.ink)
            Spacer()
            DatePicker(title, selection: selection, displayedComponents: .date)
                .labelsHidden()
        }
        .padding(Space.s4)
        .background(card)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s8) {
                    section("Billing period") {
                        VStack(spacing: Space.s3) {
                            dateRow("Start date", selection: $draftStart)
                            dateRow("End date", selection: $draftEnd)
                            Button("Apply dates", action: applyDates)
                                .buttonStyle(.pillStyle(.primary, fullWidth: true))
                                .disabled(endBeforeStart)
                        }
                        Text(periodMessage)
                            .ds(.caption)
                            .foregroundStyle(endBeforeStart ? Palette.review : Palette.inkSecondary)
                    }

                    section("Groups") {
                        NavigationLink { GroupsManagerView(kind: .debit) } label: {
                            linkRow(symbol: "fork.knife", title: "Expense groups", subtitle: "Food, Transport and more")
                        }
                        NavigationLink { GroupsManagerView(kind: .credit) } label: {
                            linkRow(symbol: "briefcase.fill", title: "Income groups", subtitle: "Salary, Freelance and more")
                        }
                    }

                    section("Bank messages") {
                        NavigationLink { SetupGuideView() } label: {
                            linkRow(symbol: "message.fill", title: "Shortcut setup", subtitle: lastMessageText)
                        }
                        notificationRow
                        duplicatesRow
                    }
                }
                .padding(Space.s4)
            }
            .background(Palette.bg)
            .navigationTitle("Settings")
            .task { authStatus = await Notifier.authorizationStatus() }
            .onAppear {
                draftStart = period.start
                draftEnd = Calendar.current.date(byAdding: .day, value: -1, to: period.end) ?? period.end
            }
        }
    }

    private var lastMessageText: String {
        guard lastMessageAt > 0 else { return "No messages received yet" }
        return "Last message: \(AppFormat.dayAndTime(Date(timeIntervalSince1970: lastMessageAt)))"
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(Palette.surface)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Space.s3) {
            Text(title).ds(.title).foregroundStyle(Palette.ink)
            content()
        }
    }

    private func linkRow(symbol: String, title: String, subtitle: String) -> some View {
        HStack(spacing: Space.s4) {
            IconDisc(symbol: symbol, color: Palette.action, tintedByInk: true)
            VStack(alignment: .leading, spacing: 0) {
                Text(title).ds(.rowTitle).foregroundStyle(Palette.ink)
                Text(subtitle).ds(.body).foregroundStyle(Palette.inkSecondary).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(Space.s4)
        .background(card)
    }

    private var notificationRow: some View {
        HStack(spacing: Space.s4) {
            IconDisc(symbol: "bell.fill", color: Palette.action, tintedByInk: true)
            VStack(alignment: .leading, spacing: 0) {
                Text("Notifications").ds(.rowTitle).foregroundStyle(Palette.ink)
                Text(notificationText).ds(.body).foregroundStyle(Palette.inkSecondary)
            }
            Spacer()
            if authStatus != .authorized {
                Button(authStatus == .notDetermined ? "Allow" : "Open Settings") {
                    Task {
                        if authStatus == .notDetermined {
                            _ = await Notifier.requestAuthorization()
                            authStatus = await Notifier.authorizationStatus()
                        } else if let url = URL(string: UIApplication.openSettingsURLString) {
                            _ = await UIApplication.shared.open(url)
                        }
                    }
                }
                .buttonStyle(.pillStyle(.secondary))
            }
        }
        .padding(Space.s4)
        .background(card)
    }

    private var duplicatesRow: some View {
        Toggle(isOn: $ignoreDuplicates) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Ignore repeated messages").ds(.rowTitle).foregroundStyle(Palette.ink)
                Text(ignoreDuplicates
                     ? "A message with the same text is skipped."
                     : "Every message is saved, even if the text repeats.")
                    .ds(.body)
                    .foregroundStyle(Palette.inkSecondary)
            }
        }
        .padding(Space.s4)
        .background(card)
    }

    private var notificationText: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "On"
        case .denied: return "Off. Turn them on to categorize expenses."
        default: return "Not set yet"
        }
    }
}
