import SwiftUI

@main
struct CalendarAutoAlarmApp: App {

    @StateObject private var alarmScheduler = AlarmScheduler()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmScheduler)
                .task {
                    await alarmScheduler.requestNotificationPermission()
                }
        }
    }
}
