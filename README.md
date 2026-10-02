# Expense Tracker

An iPhone app that turns bank SMS alerts into an automatic expense and income tracker.

- A debit alert (`HNB SMS ALERT:…`) becomes an expense and shows a notification. Tap a group button on the notification, or type a reason, and it is saved.
- A credit alert (`LKR 1,500.00 credited to…`) is saved silently as income. You tag it later in the Income tab.
- Anything the app can't read lands in Inbox as "Needs review".
- Every message is saved, even if the text repeats. Turn on **Settings → Ignore repeated messages** to skip repeats.
- You manage your own expense groups and income groups, and set the start and end date of your billing period (it follows the calendar month until you do).
- The Report tab shows income, expenses and net for a period, with totals per group.

Everything stays on the phone. There is no server.

## How messages reach the app

iOS does not let apps read your Messages. A Shortcuts automation hands each bank SMS to the app's **Log Expense from Message** action. You set it up once (about 2 minutes); the app has a step-by-step guide under **Settings → Shortcut setup**, and test buttons to check everything works.

## Project layout

| Path | What |
|---|---|
| `Packages/ExpenseCore` | Plain Swift package: the debit and credit parsers, billing periods, money formatting and report maths, with unit tests |
| `ExpenseTracker/` | The SwiftUI app: design system, SwiftData models, notification and intent services, screens |
| `project.yml` | XcodeGen project definition |
| `.github/workflows/ios.yml` | Cloud build: runs the core tests and builds the app |

Design rules live in the Expense Tracker design system (tokens, components). `ExpenseTracker/DesignSystem` mirrors it in code.

## Build and run on your iPhone (needs a Mac with Xcode)

1. Install XcodeGen: `brew install xcodegen` (or download it from github.com/yonaskolb/XcodeGen/releases).
2. In this folder run `xcodegen generate`, then open `ExpenseTracker.xcodeproj`.
3. In Xcode, select the **ExpenseTracker** target → **Signing & Capabilities**: tick *Automatically manage signing*, pick your Apple ID as the Team, and change the Bundle Identifier to something unique (for example `com.yourname.expensetracker`).
4. Plug in your iPhone, tap **Trust**, and turn on **Developer Mode** (Settings → Privacy & Security). Pick your iPhone in Xcode's device menu.
5. Press **Run**. If iOS says "Untrusted Developer", trust your Apple ID in Settings → General → VPN & Device Management.
6. Open the app, allow notifications, then use **Settings → Shortcut setup → Test a debit** to check the flow.

A free Apple ID expires the app after 7 days. Run it from Xcode again to refresh it; your data stays.

## Cloud builds

Every push runs `swift test` on the core package and builds the app on a macOS runner. The run uploads an unsigned `.ipa` and the generated `.xcodeproj`, which you can use with a sideloading tool instead of Xcode.

## Notes and limits

- Amounts are assumed to be in LKR. Bank times are read as Sri Lanka time (Asia/Colombo).
- Only the two HNB formats are supported. Send any message that lands in Inbox and a parser can be added for it.
- iOS decides when automations run. It is usually instant but not guaranteed, and nothing runs while the phone is off.
