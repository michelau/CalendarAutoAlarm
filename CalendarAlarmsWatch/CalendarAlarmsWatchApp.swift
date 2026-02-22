import SwiftUI
import WatchKit
import UserNotifications

/// Entry point for the Calendar Alarms Watch companion app.
///
/// Notification handling uses `UNUserNotificationCenterDelegate` (set up in
/// `AppDelegate`) rather than `WKNotificationScene` / `WKUserNotificationHostingController`,
/// which were deprecated in watchOS 10. When a `CALENDAR_ALARM` notification arrives
/// while the Watch app is in the foreground, `AppDelegate` plays the custom haptic
/// pattern. When the app is in the background the system delivers the notification
/// with its default Watch haptic automatically.
@main
struct CalendarAlarmsWatchApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

// MARK: - App delegate

class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
    }

    /// Play the custom haptic pattern when a CALENDAR_ALARM notification arrives
    /// while the Watch app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.content.categoryIdentifier == "CALENDAR_ALARM" {
            Task { await HapticManager.playAlarmPattern() }
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
