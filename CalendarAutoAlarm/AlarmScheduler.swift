import UserNotifications
import CalendarAutoAlarmCore

/// Schedules and cancels local notifications (alarms) for calendar events.
///
/// Each alarm is identified by a string of the form `caa:<eventID>:<alarmIndex>` so that
/// refreshing the event list cancels stale alarms and replaces them with up-to-date ones.
///
/// Also acts as `UNUserNotificationCenterDelegate` so banners appear while the app is
/// in the foreground (important for Simulator testing).
@MainActor
final class AlarmScheduler: NSObject, ObservableObject, UNUserNotificationCenterDelegate {

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Permission

    /// Requests authorization to display alerts, play sounds, and deliver time-sensitive notifications.
    /// Call once at app launch.
    func requestNotificationPermission() async {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge, .timeSensitive]
            )
            if !granted {
                print("CalendarAutoAlarm: Notification permission was denied.")
            }
        } catch {
            print("CalendarAutoAlarm: Permission request failed – \(error)")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Deliver the notification even when the app is in the foreground.
    /// Also adds it to the notification list so it persists after the banner auto-dismisses.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    // MARK: - Scheduling

    /// Schedules notifications for all alarm specs found in the given events.
    ///
    /// Any existing CalendarAutoAlarm notifications are removed first so the
    /// set of pending alarms always reflects the latest calendar state.
    func scheduleAlarms(for events: [CalendarEvent]) async {
        await cancelAllAlarms()

        for event in events {
            for (index, spec) in event.alarmSpecs.enumerated() {
                await scheduleAlarm(event: event, spec: spec, index: index)
            }
        }
    }

    /// Returns the number of currently pending alarm notifications.
    func scheduledCount() async -> Int {
        let pending = await center.pendingNotificationRequests()
        return pending.filter { $0.identifier.hasPrefix("caa:") }.count
    }

    // MARK: - Private

    private func scheduleAlarm(event: CalendarEvent, spec: AlarmSpec, index: Int) async {
        let fireDate = event.startDate.addingTimeInterval(-Double(spec.offsetBeforeEventSeconds))
        let secondsUntilFire = fireDate.timeIntervalSinceNow
        guard secondsUntilFire > 0 else { return }   // Don't schedule past alarms

        let content = UNMutableNotificationContent()
        content.title             = spec.name ?? "Upcoming Event"
        content.body              = alarmBody(event: event, spec: spec)
        content.sound             = .defaultCritical
        // Time-sensitive interruption level cuts through Focus modes and Do Not Disturb,
        // making this behave as close to a Clock alarm as iOS allows for third-party apps.
        content.interruptionLevel = .timeSensitive

        // UNTimeIntervalNotificationTrigger is simpler and more reliable on Simulator
        // than UNCalendarNotificationTrigger (avoids timezone/date-component edge cases).
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: secondsUntilFire,
            repeats: false
        )

        let identifier = "caa:\(event.id):\(index)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("CalendarAutoAlarm: Failed to schedule alarm for \"\(event.title)\" – \(error)")
        }
    }

    private func cancelAllAlarms() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .map(\.identifier)
            .filter { $0.hasPrefix("caa:") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func alarmBody(event: CalendarEvent, spec: AlarmSpec) -> String {
        let timeString = event.startDate.formatted(date: .omitted, time: .shortened)
        return "\(event.title) starts at \(timeString) (\(spec.offsetDescription))"
    }
}
