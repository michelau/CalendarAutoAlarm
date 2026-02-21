import SwiftUI

@main
struct CalendarAutoAlarmApp: App {

    @StateObject private var authManager = AuthManager()
    @StateObject private var alarmScheduler = AlarmScheduler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(alarmScheduler)
                .task {
                    await alarmScheduler.requestNotificationPermission()
                }
        }
    }
}
