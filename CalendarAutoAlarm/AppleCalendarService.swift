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

    /// Requests calendar access then returns all events in the next `daysAhead` days.
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

        return ekEvents.map { convertEvent($0) }
    }

    // MARK: - Private

    private func requestAccess() async throws -> Bool {
        if #available(iOS 17, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await store.requestAccess(to: .event)
        }
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
}
