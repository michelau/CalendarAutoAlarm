import SwiftUI

/// Root view: shows the sign-in screen when not authenticated,
/// or the event list once the user has signed in.
struct ContentView: View {

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var alarmScheduler: AlarmScheduler
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            if authManager.isSignedIn {
                EventListView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Sign Out") {
                                authManager.signOut()
                                viewModel.events = []
                            }
                        }
                    }
                    .task {
                        await viewModel.refresh(accessToken: authManager.accessToken ?? "")
                    }
            } else {
                SignInView()
            }
        }
    }
}
