import SwiftUI

/// Root view: shows the event list and triggers a calendar-access request on first launch.
struct ContentView: View {

    @EnvironmentObject private var alarmScheduler: AlarmScheduler
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            EventListView(viewModel: viewModel)
        }
        .task {
            await viewModel.refresh()
        }
    }
}
