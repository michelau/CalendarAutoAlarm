import SwiftUI

/// Entry point for the Calendar Alarms Watch companion app.
///
/// The app has two scenes:
/// - ``WindowGroup`` — a minimal "home" view shown when the user opens the app directly.
/// - ``WKNotificationScene`` — intercepts incoming `CALENDAR_ALARM` notifications and
///   shows ``NotificationView`` while simultaneously triggering the custom haptic pattern
///   via ``HapticManager``.
@main
struct CalendarAlarmsWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
        WKNotificationScene(
            controller: AlarmNotificationController.self,
            category: "CALENDAR_ALARM"
        )
    }
}

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
