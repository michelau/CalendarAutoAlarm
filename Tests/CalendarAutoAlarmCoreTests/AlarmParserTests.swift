import XCTest
@testable import CalendarAutoAlarmCore

final class AlarmParserTests: XCTestCase {

    var parser: AlarmParser!

    override func setUp() {
        super.setUp()
        parser = AlarmParser()
    }

    // MARK: - Duration parsing

    func testParseDuration_zero() {
        XCTAssertEqual(parser.parseDuration("0"), 0)
    }

    func testParseDuration_minutes() {
        XCTAssertEqual(parser.parseDuration("5m"),  300)
        XCTAssertEqual(parser.parseDuration("30m"), 1800)
    }

    func testParseDuration_hours() {
        XCTAssertEqual(parser.parseDuration("1h"), 3600)
        XCTAssertEqual(parser.parseDuration("2h"), 7200)
    }

    func testParseDuration_seconds() {
        XCTAssertEqual(parser.parseDuration("30s"), 30)
        XCTAssertEqual(parser.parseDuration("90s"), 90)
    }

    func testParseDuration_hoursAndMinutes() {
        XCTAssertEqual(parser.parseDuration("1h30m"), 5400)
        XCTAssertEqual(parser.parseDuration("2h15m"), 8100)
    }

    func testParseDuration_hoursMinutesSeconds() {
        XCTAssertEqual(parser.parseDuration("1h30m45s"), 5445)
    }

    func testParseDuration_invalid_letters() {
        XCTAssertNil(parser.parseDuration("abc"))
        XCTAssertNil(parser.parseDuration("5x"))
        XCTAssertNil(parser.parseDuration("wakeup"))
    }

    func testParseDuration_invalid_bareNumber() {
        // A plain number without a unit (other than "0") is not a valid duration
        XCTAssertNil(parser.parseDuration("5"))
        XCTAssertNil(parser.parseDuration("60"))
    }

    func testParseDuration_invalid_empty() {
        XCTAssertNil(parser.parseDuration(""))
    }

    func testParseDuration_invalid_trailingDigits() {
        // "1h30" has trailing digits without a unit
        XCTAssertNil(parser.parseDuration("1h30"))
    }

    // MARK: - Full description parsing

    func testParse_simpleMinutes() {
        let specs = parser.parse(description: "alarm: 5m")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 300)
        XCTAssertNil(specs[0].name)
    }

    func testParse_simpleHour() {
        let specs = parser.parse(description: "alarm: 1h")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 3600)
    }

    func testParse_hoursAndMinutes() {
        let specs = parser.parse(description: "alarm: 1h30m")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 5400)
    }

    func testParse_atEventTime() {
        let specs = parser.parse(description: "alarm: 0")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 0)
        XCTAssertNil(specs[0].name)
    }

    func testParse_namedAlarm_singleWord() {
        let specs = parser.parse(description: "alarm: wakeup 30m")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].name, "wakeup")
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 1800)
    }

    func testParse_namedAlarm_multiWord() {
        let specs = parser.parse(description: "alarm: morning meeting 1h")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].name, "morning meeting")
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 3600)
    }

    func testParse_caseInsensitive_upper() {
        let specs = parser.parse(description: "ALARM: 5m")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 300)
    }

    func testParse_caseInsensitive_mixed() {
        let specs = parser.parse(description: "Alarm: 5m")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 300)
    }

    func testParse_multipleAlarms() {
        let description = """
        Meet with client
        alarm: 1h
        alarm: reminder 15m
        """
        let specs = parser.parse(description: description)
        XCTAssertEqual(specs.count, 2)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 3600)
        XCTAssertNil(specs[0].name)
        XCTAssertEqual(specs[1].offsetBeforeEventSeconds, 900)
        XCTAssertEqual(specs[1].name, "reminder")
    }

    func testParse_noAlarm() {
        let specs = parser.parse(description: "Just a regular event description with no alarm")
        XCTAssertEqual(specs.count, 0)
    }

    func testParse_emptyDescription() {
        let specs = parser.parse(description: "")
        XCTAssertEqual(specs.count, 0)
    }

    func testParse_alarmInMultilineDescription() {
        let description = """
        Presentation to management team
        Location: Conference Room B
        alarm: 30m
        Remember to bring laptop
        """
        let specs = parser.parse(description: description)
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 1800)
    }

    func testParse_extraWhitespaceAroundContent() {
        let specs = parser.parse(description: "   alarm:   wakeup   15m   ")
        XCTAssertEqual(specs.count, 1)
        XCTAssertEqual(specs[0].name, "wakeup")
        XCTAssertEqual(specs[0].offsetBeforeEventSeconds, 900)
    }

    func testParse_invalidDurationIgnored() {
        // "alarm: invalid" has no valid duration → should produce no spec
        let specs = parser.parse(description: "alarm: invalid")
        XCTAssertEqual(specs.count, 0)
    }

    // MARK: - AlarmSpec.offsetDescription

    func testOffsetDescription_atEventTime() {
        let spec = AlarmSpec(name: nil, offsetBeforeEventSeconds: 0)
        XCTAssertEqual(spec.offsetDescription, "at event time")
    }

    func testOffsetDescription_minutes() {
        let spec = AlarmSpec(name: nil, offsetBeforeEventSeconds: 300)
        XCTAssertEqual(spec.offsetDescription, "5m before")
    }

    func testOffsetDescription_hours() {
        let spec = AlarmSpec(name: nil, offsetBeforeEventSeconds: 3600)
        XCTAssertEqual(spec.offsetDescription, "1h before")
    }

    func testOffsetDescription_hoursAndMinutes() {
        let spec = AlarmSpec(name: nil, offsetBeforeEventSeconds: 5400)
        XCTAssertEqual(spec.offsetDescription, "1h 30m before")
    }

    func testOffsetDescription_seconds() {
        let spec = AlarmSpec(name: nil, offsetBeforeEventSeconds: 45)
        XCTAssertEqual(spec.offsetDescription, "45s before")
    }
}
