import Foundation

/// A Google Calendar event, with any alarm specifications parsed from its description.
public struct CalendarEvent: Identifiable, Equatable, Sendable {

    /// Google Calendar event identifier.
    public let id: String

    /// Event title (the "summary" field in the API).
    public let title: String

    /// Start date/time of the event.
    public let startDate: Date

    /// End date/time of the event (nil for all-day events parsed without an end).
    public let endDate: Date?

    /// Raw event description text from Google Calendar.
    public let description: String?

    /// Alarm specifications parsed from the description (may be empty).
    public let alarmSpecs: [AlarmSpec]

    public init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date? = nil,
        description: String? = nil,
        alarmSpecs: [AlarmSpec] = []
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.description = description
        self.alarmSpecs = alarmSpecs
    }
}
