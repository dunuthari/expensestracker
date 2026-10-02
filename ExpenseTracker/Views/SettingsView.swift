import SwiftUI
import SwiftData
import UserNotifications
import ExpenseCore

struct SettingsView: View {
    @AppStorage(SettingsKey.periodStartDay) private var startDay = 1
    @AppStorage(SettingsKey.lastMessageAt) private var lastMessageAt = 0.0
    @AppStorage(SettingsKey.ignoreDuplicates) private var ignoreDuplicates = false
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    private var period: BillingPeriod { BillingPeriod.containing(Date(), startDay: startDay) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.s8) {
                    section("Billing period") {
                        HStack {
                            Text("Period starts on day").ds(.rowTitle).foregroundStyle(Palette.ink)
                            Spacer()
                            Picker("Start day", selection: $startDay) {
                                ForEach(Array(BillingPeriod.startDayRange), id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Palette.ink)
                        }
                        .padding(Space.s4)
                        .background(card)
                        Text("Current period: \(period.label()). Totals reset on day \(startDay) of each month.")
                            .ds(.caption)
                            .foregroundStyle(Palette.inkSecondary)
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
