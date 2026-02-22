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

/// Home view shown when the user opens the Watch app directly.
///
/// The "Test Haptic" button lets the user immediately confirm that
/// (a) the Watch app is installed and running, and
/// (b) the custom 3·1·2 haptic sequence is working on this device.
struct WatchHomeView: View {
    @State private var isTesting = false

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            Text("Calendar Alarms")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Alarms fire when your\niPhone screen is locked.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                guard !isTesting else { return }
                isTesting = true
                Task {
                    await HapticManager.playAlarmPattern()
                    isTesting = false
                }
            } label: {
                Label(
                    isTesting ? "Playing…" : "Test Haptic",
                    systemImage: isTesting ? "waveform" : "hand.tap"
                )
                .font(.caption)
            }
            .disabled(isTesting)
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
            .padding(.top, 4)
        }
        .padding()
    }
}
