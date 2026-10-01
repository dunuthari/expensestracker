import UIKit
import UserNotifications

/// Owns the notification delegate so action taps work even when the app was not running.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionID = response.actionIdentifier
        let entryID = response.notification.request.content.userInfo["entryID"] as? String
        let text = (response as? UNTextInputNotificationResponse)?.userText
        await MainActor.run {
            Notifier.handle(actionID: actionID, entryID: entryID, text: text)
        }
    }
}
