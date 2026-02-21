import UserNotifications
import CalendarAutoAlarmCore

/// Schedules and cancels local notifications (alarms) for calendar events.
///
/// Each alarm is identified by a string of the form `<eventID>:<alarmIndex>` so that
/// refreshing the event list cancels stale alarms and replaces them with up-to-date ones.
@MainActor
final class AlarmScheduler: ObservableObject {

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    /// Requests authorization to display alerts and play sounds.
    /// Call once at app launch.
    func requestNotificationPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if !granted {
                print("CalendarAutoAlarm: Notification permission was denied.")
            }
        } catch {
            print("CalendarAutoAlarm: Permission request failed – \(error)")
        }
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
        guard fireDate > Date() else { return }   // Don't schedule past alarms

        let content = UNMutableNotificationContent()
        content.title  = spec.name ?? "Upcoming Event"
        content.body   = alarmBody(event: event, spec: spec)
        content.sound  = .defaultCritical

        var dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        dateComponents.timeZone = TimeZone.current

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
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
