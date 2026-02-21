import SwiftUI
import CalendarAutoAlarmCore

/// ViewModel that loads upcoming calendar events from the on-device store.
@MainActor
final class CalendarViewModel: ObservableObject {

    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var permissionDenied = false
    @Published var scheduledCount = 0

    private let service = AppleCalendarService()

    /// Requests calendar access (if not yet determined) then re-fetches events for the next 7 days.
    func refresh() async {
        isLoading       = true
        errorMessage    = nil
        permissionDenied = false
        do {
            events = try await service.fetchEvents(daysAhead: 7)
        } catch AppleCalendarError.permissionDenied {
            permissionDenied = true
            errorMessage = AppleCalendarError.permissionDenied.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
