import EventKit
import CalendarAutoAlarmCore

// MARK: - Error

/// Errors thrown by ``AppleCalendarService``.
enum AppleCalendarError: Error, LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        "Calendar access is required. Please allow access in Settings → Privacy & Security → Calendars."
    }
}

// MARK: - Service

/// Fetches events from the on-device Calendar store (including Google, iCloud, Exchange
/// calendars already synced through iOS Settings) and attaches parsed alarm specs.
final class AppleCalendarService {

    private let store = EKEventStore()
    private let alarmParser = AlarmParser()

    /// Requests calendar access then returns upcoming events for the next `daysAhead` days.
    ///
    /// Only events that have **not yet started** are returned. Additionally, events that
    /// carry `alarm:` directives but whose every alarm fire-time has already passed are
    /// excluded — there is nothing left to schedule for them.
    ///
    /// - Throws: ``AppleCalendarError/permissionDenied`` when the user has not granted
    ///   (or has revoked) calendar access.
    func fetchEvents(daysAhead: Int = 7) async throws -> [CalendarEvent] {
        let granted = try await requestAccess()
        guard granted else { throw AppleCalendarError.permissionDenied }

        let now    = Date()
        // Calendar.date(byAdding:) is guaranteed non-nil for valid components; force-unwrap is safe here.
        let future = Calendar.current.date(byAdding: .day, value: daysAhead, to: now)!

        let predicate = store.predicateForEvents(withStart: now, end: future, calendars: nil)
        let ekEvents  = store.events(matching: predicate)

        return ekEvents
            .map { convertEvent($0) }
            .filter { isRelevant($0, now: now) }
    }

    // MARK: - Private

    private func requestAccess() async throws -> Bool {
        return try await store.requestFullAccessToEvents()
    }

    private func convertEvent(_ ek: EKEvent) -> CalendarEvent {
        let notes      = ek.notes
        let alarmSpecs = notes.map { alarmParser.parse(description: $0) } ?? []

        return CalendarEvent(
            id:          ek.eventIdentifier,
            title:       ek.title ?? "(No title)",
            startDate:   ek.startDate,
            endDate:     ek.endDate,
            description: notes,
            alarmSpecs:  alarmSpecs
        )
    }

    /// Returns `true` when an event is still worth showing and scheduling.
    ///
    /// An event is considered irrelevant when:
    /// - Its start time is already in the past (the event has already begun), **or**
    /// - It has one or more alarm directives but every alarm's fire time has already passed
    ///   (there is no alarm left to schedule for it).
    ///
    /// Events with no alarm directives that haven't started yet are always kept so the
    /// full upcoming calendar picture remains visible.
    func isRelevant(_ event: CalendarEvent, now: Date) -> Bool {
        // Drop events that have already started.
        guard event.startDate > now else { return false }

        // If there are alarm specs, at least one alarm must still be in the future.
        if !event.alarmSpecs.isEmpty {
            let hasUpcomingAlarm = event.alarmSpecs.contains { spec in
                let fireDate = event.startDate.addingTimeInterval(-Double(spec.offsetBeforeEventSeconds))
                return fireDate > now
            }
            return hasUpcomingAlarm
        }

        return true
    }
}
