import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Google Calendar API response models

/// Top-level response from `GET /calendar/v3/calendars/{calendarId}/events`.
public struct GoogleCalendarEventList: Codable, Sendable {
    public let items: [GoogleCalendarEventItem]?
    public let nextPageToken: String?
}

/// A single event item from the Google Calendar API.
public struct GoogleCalendarEventItem: Codable, Sendable {
    public let id: String
    public let summary: String?
    public let description: String?
    public let start: GoogleCalendarEventTime?
    public let end: GoogleCalendarEventTime?
}

/// The start or end time of a Google Calendar event.
/// Either `dateTime` (for timed events) or `date` (for all-day events) is populated.
public struct GoogleCalendarEventTime: Codable, Sendable {
    /// RFC 3339 date-time string for timed events (e.g. `"2025-06-01T09:00:00-07:00"`).
    public let dateTime: String?
    /// Date-only string for all-day events (e.g. `"2025-06-01"`).
    public let date: String?
    /// IANA time zone identifier (e.g. `"America/Los_Angeles"`).
    public let timeZone: String?
}

// MARK: - Error type

/// Errors thrown by ``GoogleCalendarService``.
public enum GoogleCalendarError: Error, LocalizedError, Sendable {
    case invalidResponse
    case apiError(statusCode: Int, body: String)
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Google Calendar API."
        case .apiError(let code, let body):
            return "Google Calendar API error \(code): \(body)"
        case .unauthorized:
            return "Not authorized. Please sign in with Google."
        }
    }
}

// MARK: - Service

/// Fetches events from the Google Calendar REST API and attaches parsed alarm specs.
public final class GoogleCalendarService: @unchecked Sendable {

    private let baseURL = "https://www.googleapis.com/calendar/v3"
    private let session: URLSession
    private let alarmParser: AlarmParser

    public init(session: URLSession = .shared, alarmParser: AlarmParser = AlarmParser()) {
        self.session = session
        self.alarmParser = alarmParser
    }

    /// Fetches upcoming events that contain alarm directives.
    ///
    /// - Parameters:
    ///   - calendarID: Calendar identifier. Use `"primary"` for the signed-in user's main calendar.
    ///   - accessToken: A valid OAuth 2.0 access token with the
    ///     `https://www.googleapis.com/auth/calendar.readonly` scope.
    ///   - daysAhead: How many calendar days ahead to look (default: 7).
    /// - Returns: All events in the window, each with `alarmSpecs` populated from the description.
    public func fetchEvents(
        calendarID: String = "primary",
        accessToken: String,
        daysAhead: Int = 7
    ) async throws -> [CalendarEvent] {
        let now = Date()
        let future = Calendar.current.date(byAdding: .day, value: daysAhead, to: now) ?? now

        var components = URLComponents(string: "\(baseURL)/calendars/\(calendarID)/events")!
        let formatter = ISO8601DateFormatter()
        components.queryItems = [
            URLQueryItem(name: "timeMin",      value: formatter.string(from: now)),
            URLQueryItem(name: "timeMax",      value: formatter.string(from: future)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy",      value: "startTime"),
            URLQueryItem(name: "maxResults",   value: "250")
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw GoogleCalendarError.invalidResponse
        }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw GoogleCalendarError.unauthorized }
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GoogleCalendarError.apiError(statusCode: http.statusCode, body: body)
        }

        let list = try JSONDecoder().decode(GoogleCalendarEventList.self, from: data)
        return (list.items ?? []).compactMap { convertEvent($0) }
    }

    // MARK: - Private

    private func convertEvent(_ item: GoogleCalendarEventItem) -> CalendarEvent? {
        guard let startDate = parseEventTime(item.start) else { return nil }

        let description = item.description
        let alarmSpecs = description.map { alarmParser.parse(description: $0) } ?? []

        return CalendarEvent(
            id: item.id,
            title: item.summary ?? "(No title)",
            startDate: startDate,
            endDate: parseEventTime(item.end),
            description: description,
            alarmSpecs: alarmSpecs
        )
    }

    private func parseEventTime(_ time: GoogleCalendarEventTime?) -> Date? {
        guard let time else { return nil }
        if let dateTimeStr = time.dateTime {
            return ISO8601DateFormatter().date(from: dateTimeStr)
        }
        if let dateStr = time.date {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone(identifier: "UTC")
            return f.date(from: dateStr)
        }
        return nil
    }
}
