import XCTest
@testable import CalendarAutoAlarmCore

/// Tests for the event-relevance filtering logic that mirrors ``AppleCalendarService.isRelevant(_:now:)``.
///
/// Because ``AppleCalendarService`` lives in the iOS app target (not the core package)
/// and depends on EventKit, these tests exercise the identical predicate logic using
/// ``CalendarEvent`` values constructed directly.
final class EventRelevanceTests: XCTestCase {

    // Reference "now" used across all tests so results are deterministic.
    let now = Date()

    // MARK: - Helpers

    /// Applies the same filter logic as ``AppleCalendarService.isRelevant(_:now:)``.
    private func isRelevant(_ event: CalendarEvent, now: Date) -> Bool {
        guard event.startDate > now else { return false }
        guard !event.alarmSpecs.isEmpty else { return false }
        return event.alarmSpecs.contains { spec in
            let fireDate = event.startDate.addingTimeInterval(-Double(spec.offsetBeforeEventSeconds))
            return fireDate > now
        }
    }

    private func event(
        startOffset: TimeInterval,
        alarmSpecs: [AlarmSpec] = []
    ) -> CalendarEvent {
        CalendarEvent(
            id: UUID().uuidString,
            title: "Test",
            startDate: now.addingTimeInterval(startOffset),
            alarmSpecs: alarmSpecs
        )
    }

    // MARK: - Already-started events

    func testAlreadyStartedEvent_isFiltered() {
        let e = event(startOffset: -60)   // started 1 minute ago
        XCTAssertFalse(isRelevant(e, now: now))
    }

    func testEventStartingRightNow_isFiltered() {
        // startDate == now is not strictly > now, so the event is considered started.
        let e = CalendarEvent(
            id: "x", title: "Now", startDate: now, alarmSpecs: []
        )
        XCTAssertFalse(isRelevant(e, now: now))
    }

    func testFutureEventNoAlarms_isFiltered() {
        let e = event(startOffset: 3600)   // starts in 1 hour, no alarms
        XCTAssertFalse(isRelevant(e, now: now))
    }

    // MARK: - Events with upcoming alarms

    func testFutureEventWithUpcomingAlarm_isKept() {
        // Event in 1 hour, alarm 30 min before (fires in 30 min from now)
        let e = event(startOffset: 3600, alarmSpecs: [AlarmSpec(offsetBeforeEventSeconds: 1800)])
        XCTAssertTrue(isRelevant(e, now: now))
    }

    func testFutureEventWithAlarmAtEventTime_isKept() {
        // Event in 1 hour, alarm at event start (fires in 60 min from now)
        let e = event(startOffset: 3600, alarmSpecs: [AlarmSpec(offsetBeforeEventSeconds: 0)])
        XCTAssertTrue(isRelevant(e, now: now))
    }

    // MARK: - Missed alarm window

    func testFutureEventAllAlarmsMissed_isFiltered() {
        // Event starts in 10 minutes, but alarm was 1 hour before — fire time was 50 min ago.
        let e = event(startOffset: 600, alarmSpecs: [AlarmSpec(offsetBeforeEventSeconds: 3600)])
        XCTAssertFalse(isRelevant(e, now: now))
    }

    func testFutureEventSomeAlarmsMissedSomeUpcoming_isKept() {
        // Event starts in 10 minutes.
        // Alarm 1: 1 hour before — fire time 50 min ago (missed).
        // Alarm 2: 5 minutes before — fire time in 5 min (still upcoming).
        let e = event(startOffset: 600, alarmSpecs: [
            AlarmSpec(offsetBeforeEventSeconds: 3600),
            AlarmSpec(offsetBeforeEventSeconds: 300)
        ])
        XCTAssertTrue(isRelevant(e, now: now))
    }

    func testFutureEventAllAlarmsJustMissed_isFiltered() {
        // Event starts in 5 minutes, alarm was 10 minutes before — fire time 5 min ago.
        let e = event(startOffset: 300, alarmSpecs: [AlarmSpec(offsetBeforeEventSeconds: 600)])
        XCTAssertFalse(isRelevant(e, now: now))
    }

    func testFutureEventAlarmFiresExactlyNow_isFiltered() {
        // Alarm fire date == now is not strictly > now; treat as missed.
        let startOffset: TimeInterval = 600
        let alarmOffset = Int(startOffset)   // fires exactly at now
        let e = event(startOffset: startOffset, alarmSpecs: [AlarmSpec(offsetBeforeEventSeconds: alarmOffset)])
        XCTAssertFalse(isRelevant(e, now: now))
    }

    // MARK: - Multiple alarms, all missed

    func testFutureEventMultipleAllarmsAllMissed_isFiltered() {
        let e = event(startOffset: 60, alarmSpecs: [
            AlarmSpec(name: "early",  offsetBeforeEventSeconds: 3600),
            AlarmSpec(name: "late",   offsetBeforeEventSeconds: 120)
        ])
        XCTAssertFalse(isRelevant(e, now: now))
    }
}
