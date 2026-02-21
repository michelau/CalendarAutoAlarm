import Foundation

/// Represents an alarm specification parsed from a calendar event description.
///
/// Created from text such as `alarm: wakeup 5m` in a Google Calendar event's description.
public struct AlarmSpec: Equatable, Codable, Sendable {

    /// Optional user-facing name for the alarm (e.g. "wakeup", "morning meeting").
    public let name: String?

    /// Number of seconds before the event at which to trigger the alarm.
    /// Use 0 for an alarm at event start time.
    public let offsetBeforeEventSeconds: Int

    public init(name: String? = nil, offsetBeforeEventSeconds: Int) {
        self.name = name
        self.offsetBeforeEventSeconds = offsetBeforeEventSeconds
    }

    /// A human-readable description of the offset, e.g. "5m before".
    public var offsetDescription: String {
        if offsetBeforeEventSeconds == 0 {
            return "at event time"
        }
        let hours = offsetBeforeEventSeconds / 3600
        let minutes = (offsetBeforeEventSeconds % 3600) / 60
        let seconds = offsetBeforeEventSeconds % 60

        var parts: [String] = []
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }
        if seconds > 0 { parts.append("\(seconds)s") }

        return parts.joined(separator: " ") + " before"
    }
}
