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
        // Fire the custom haptic immediately so the wearer feels the pattern.
        HapticManager.playAlarmPattern()
    }
}
