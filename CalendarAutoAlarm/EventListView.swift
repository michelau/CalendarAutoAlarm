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
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)

            Text(event.startDate, style: .relative)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !event.alarmSpecs.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.caption)
                    ForEach(Array(event.alarmSpecs.enumerated()), id: \.offset) { _, spec in
                        Text(alarmLabel(spec))
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func alarmLabel(_ spec: AlarmSpec) -> String {
        if let name = spec.name {
            return "\(name) – \(spec.offsetDescription)"
        }
        return spec.offsetDescription
    }
}
