import SwiftUI
import CalendarAutoAlarmCore

/// ViewModel that loads upcoming Google Calendar events and keeps the UI in sync.
@MainActor
final class CalendarViewModel: ObservableObject {

    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var scheduledCount = 0

    private let service = GoogleCalendarService()

    /// Re-fetches events from Google Calendar for the next 7 days.
    func refresh(accessToken: String) async {
        guard !accessToken.isEmpty else {
            errorMessage = "No access token. Please sign in again."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            events = try await service.fetchEvents(
                accessToken: accessToken,
                daysAhead: 7
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
