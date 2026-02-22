import WatchKit
import SwiftUI
import UserNotifications

/// Handles incoming `CALENDAR_ALARM` notifications on Apple Watch.
///
/// When a notification fires the system calls ``didReceive(_:)`` before displaying
/// the notification UI. We use that hook to play the custom haptic pattern so the
/// wearer feels the distinct rhythm immediately, before they look at the screen.
class AlarmNotificationController: WKUserNotificationHostingController<NotificationView> {

    private var alarmTitle   = "Calendar Alarm"
    private var alarmMessage = ""

    // MARK: - WKUserNotificationHostingController

    override var body: NotificationView {
        NotificationView(title: alarmTitle, message: alarmMessage)
    }

    override func didReceive(_ notification: UNNotification) {
        alarmTitle   = notification.request.content.title
        alarmMessage = notification.request.content.body
        // Launch the haptic pattern in a Task so it uses Swift cooperative threading
        // (Task.sleep) rather than DispatchQueue.main.asyncAfter. The latter is
        // unreliable inside didReceive() because the main run loop timer queue is
        // not guaranteed to be processed after this method returns.
        Task { await HapticManager.playAlarmPattern() }
    }
}
