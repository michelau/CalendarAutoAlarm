import SwiftUI
import UserNotifications

/// Entry point for the Calendar Alarms Watch companion app.
///
/// Notification handling uses a `UNUserNotificationCenterDelegate` held as a
/// `@StateObject` and wired up in `.task {}` on the root view.  This avoids
/// `@WKApplicationDelegateAdaptor` / `WKApplicationDelegate`, which initialise
/// synchronously at app startup and can prevent the process from launching on
/// some watchOS 26 personal-team builds.
///
/// When a `CALENDAR_ALARM` notification arrives while the Watch app is in the
/// foreground, `AlarmDelegate` plays the custom haptic pattern.  When the app
/// is in the background the system delivers the notification with the default
/// Watch haptic automatically.
@main
struct CalendarAlarmsWatchApp: App {
    @StateObject private var alarmDelegate = AlarmDelegate()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .task {
                    UNUserNotificationCenter.current().delegate = alarmDelegate
                }
        }
    }
}

// MARK: - Notification delegate

/// Handles foreground `CALENDAR_ALARM` notifications by playing the custom
/// haptic pattern; all other notifications use the default presentation.
final class AlarmDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {

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
