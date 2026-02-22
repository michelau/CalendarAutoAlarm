import SwiftUI
import UserNotifications

/// Entry point for the Calendar Alarms Watch companion app.
///
/// The notification delegate is wired up synchronously in `init()` so it is
/// ready before the first SwiftUI render — avoiding any timing window where an
/// incoming `CALENDAR_ALARM` notification could arrive before the delegate is set.
///
/// When a `CALENDAR_ALARM` notification arrives while the Watch app is in the
/// foreground, `AlarmDelegate` plays the custom haptic pattern.  When the app
/// is in the background the system delivers the notification with the default
/// Watch haptic automatically.
@main
struct CalendarAlarmsWatchApp: App {
    private let alarmDelegate = AlarmDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = alarmDelegate
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

// MARK: - Notification delegate

/// Handles foreground `CALENDAR_ALARM` notifications by playing the custom
/// haptic pattern; all other notifications use the default presentation.
final class AlarmDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.content.categoryIdentifier == "CALENDAR_ALARM" {
            await HapticManager.playAlarmPattern()
        }
        return [.banner, .sound]
    }
}

// MARK: - Home view

/// Minimal home view shown when the user taps the app icon on the Watch directly.
struct WatchHomeView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            Text("Calendar Alarms")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Alarms fire automatically from your iPhone.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
