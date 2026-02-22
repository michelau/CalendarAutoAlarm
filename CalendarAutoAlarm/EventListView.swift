import SwiftUI
import CalendarAutoAlarmCore

/// Displays the list of upcoming calendar events and their alarms.
struct EventListView: View {

    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject private var alarmScheduler: AlarmScheduler

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading events…")
            } else if viewModel.permissionDenied {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("Calendar Access Required")
                        .font(.headline)
                    Text("Allow access in Settings → Privacy & Security → Calendars, then pull down to refresh.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await viewModel.refresh() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if viewModel.events.isEmpty {
                ContentUnavailableView(
                    "No upcoming events",
                    systemImage: "calendar",
                    description: Text("Add \"alarm: 5m\" to an event's description or notes to schedule an automatic alarm.")
                )
            } else {
                List(viewModel.events) { event in
                    EventRow(event: event)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Calendar Alarms")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Group {
                    if !viewModel.isLoading {
                        Button {
                            Task { await viewModel.refresh() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Group {
                    if viewModel.scheduledCount > 0 {
                        Label("\(viewModel.scheduledCount) alarm\(viewModel.scheduledCount == 1 ? "" : "s")",
                              systemImage: "bell.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        .onChange(of: viewModel.events) { _, newEvents in
            Task {
                await alarmScheduler.scheduleAlarms(for: newEvents)
                viewModel.scheduledCount = await alarmScheduler.scheduledCount()
            }
        }
    }
}

/// A single row in the event list, showing event title, time and any alarms.
struct EventRow: View {

    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(event.title)
                .font(.headline)

            // Live countdown to event start
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Event ") + Text(event.startDate, style: .relative)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Live countdown per alarm — past alarms omitted, remaining sorted soonest first
            ForEach(upcomingAlarms, id: \.offset) { offset, spec in
                let fireDate = event.startDate
                    .addingTimeInterval(-Double(spec.offsetBeforeEventSeconds))
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.caption)
                    alarmCountdownText(spec: spec, fireDate: fireDate)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }

    /// Alarm specs that haven't fired yet, sorted by fire time (soonest first).
    private var upcomingAlarms: [(offset: Int, spec: AlarmSpec)] {
        let now = Date()
        return event.alarmSpecs
            .enumerated()
            .map { (offset: $0.offset, spec: $0.element) }
            .filter { item in
                let fireDate = event.startDate
                    .addingTimeInterval(-Double(item.spec.offsetBeforeEventSeconds))
                return fireDate > now
            }
            .sorted { a, b in
                // Larger offset fires earlier (e.g. 1h before fires before 30m before)
                a.spec.offsetBeforeEventSeconds > b.spec.offsetBeforeEventSeconds
            }
    }

    @ViewBuilder
    private func alarmCountdownText(spec: AlarmSpec, fireDate: Date) -> some View {
        if let name = spec.name {
            Text("\(name) – ") + Text(fireDate, style: .relative)
        } else {
            Text("Alarm – ") + Text(fireDate, style: .relative)
        }
    }
}
