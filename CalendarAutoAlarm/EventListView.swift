import SwiftUI
import CalendarAutoAlarmCore

/// Displays the list of upcoming calendar events and their alarms.
struct EventListView: View {

    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject private var alarmScheduler: AlarmScheduler

    var body: some View {
        Group {
            // Only replace the list with a spinner on the very first load (no events yet).
            // For pull-to-refresh the .refreshable modifier handles its own animation;
            // toggling isLoading during that animation causes the "refresh control not idle" warning.
            if viewModel.isLoading && viewModel.events.isEmpty {
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

// MARK: - EventRow

/// A single row in the event list showing the event title, date/time range, start
/// countdown, and one ``AlarmRow`` per alarm spec (sorted soonest first).
struct EventRow: View {

    let event: CalendarEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(event.title)
                .font(.headline)

            // Date + time range (e.g. "Mon, Feb 22  ·  9:00 AM – 10:30 AM")
            Text(eventDateRange)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Live countdown to event start
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Starts ") + Text(event.startDate, style: .relative)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // All alarms sorted by soonest fire time — never removed, expired ones labelled
            ForEach(sortedAlarms, id: \.offset) { _, spec in
                AlarmRow(event: event, spec: spec)
            }
        }
        .padding(.vertical, 4)
    }

    /// Formatted date + time range string for the event.
    private var eventDateRange: String {
        let day       = event.startDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
        let startTime = event.startDate.formatted(date: .omitted, time: .shortened)
        if let end = event.endDate {
            let endTime = end.formatted(date: .omitted, time: .shortened)
            return "\(day)  ·  \(startTime) – \(endTime)"
        }
        return "\(day)  ·  \(startTime)"
    }

    /// All alarm specs sorted soonest-fire-first (largest offset = earliest fire time).
    private var sortedAlarms: [(offset: Int, spec: AlarmSpec)] {
        event.alarmSpecs
            .enumerated()
            .map { (offset: $0.offset, spec: $0.element) }
            .sorted { $0.spec.offsetBeforeEventSeconds > $1.spec.offsetBeforeEventSeconds }
    }
}

// MARK: - AlarmRow

/// Displays a single alarm spec: an offset title and a live countdown that shows
/// "Expired" once the alarm fire time has passed (never counts upward).
struct AlarmRow: View {

    let event: CalendarEvent
    let spec: AlarmSpec

    /// The exact moment this alarm should fire.
    private var fireDate: Date {
        event.startDate.addingTimeInterval(-Double(spec.offsetBeforeEventSeconds))
    }

    /// Human-readable label: "wakeup – 30m before" or "30m before".
    private var alarmLabel: String {
        if let name = spec.name {
            return "\(name) – \(spec.offsetDescription)"
        }
        return spec.offsetDescription
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Offset title
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.caption)
                Text(alarmLabel)
                    .font(.caption.weight(.semibold))
            }

            // Live countdown — transitions to "Expired" once fireDate is reached.
            // TimelineView(.everyMinute) keeps the expired check current; the system
            // continuously updates Text(.relative) on its own within each minute.
            TimelineView(.everyMinute) { context in
                let expired = fireDate <= context.date
                Group {
                    if expired {
                        Text("Expired")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(fireDate, style: .relative)
                            .foregroundStyle(.primary)
                    }
                }
                .font(.caption2)
            }
            .padding(.leading, 16)
        }
    }
}

