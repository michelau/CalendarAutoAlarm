# CalendarAutoAlarm

An iPhone app that automatically schedules named alarms for events in your calendar
whenever those events contain a special alarm directive in their notes field.

No Google sign-in or cloud setup required — the app reads calendars already synced
to your iPhone (Google Calendar, iCloud, Exchange, and any other account configured
in **Settings → Calendar → Accounts**).

---

## How it works

Add an `alarm:` line to the **notes** of any calendar event:

| Notes text               | Effect                                               |
|--------------------------|------------------------------------------------------|
| `alarm: 5m`              | Alarm notification **5 minutes** before the event   |
| `alarm: 1h`              | Alarm notification **1 hour** before the event       |
| `alarm: 1h30m`           | Alarm notification **1 hour 30 minutes** before      |
| `alarm: 30s`             | Alarm notification **30 seconds** before             |
| `alarm: 0`               | Alarm notification **at event start time**           |
| `alarm: wakeup 30m`      | Alarm named **"wakeup"**, 30 minutes before          |
| `alarm: morning 1h`      | Alarm named **"morning"**, 1 hour before             |

Multiple `alarm:` lines in the same notes field create multiple alarms.  
The keyword `alarm:` is **case-insensitive**.

The app checks the next 7 days of your calendar and schedules a local iOS notification
for each alarm it finds. Pull-to-refresh or the ↺ button re-syncs at any time.

---

## Requirements

* Xcode 15+
* iOS 16+ device or simulator
* Calendar permission granted to the app

---

## Setup

1. Open `CalendarAutoAlarm.xcodeproj` in Xcode.
2. Select your development team under *Signing & Capabilities*.
3. Run on a device or simulator (**⌘R**).
4. On first launch, grant **Calendar** access when prompted.

> **Using Google Calendar on iPhone?**  
> Add your Google account in **Settings → Calendar → Accounts → Add Account → Google**.
> Its events will then appear in the on-device calendar store and be visible to this app.

---

## Project structure

```
CalendarAutoAlarm/
├── Package.swift                          # Swift Package – core library + tests
├── Sources/CalendarAutoAlarmCore/
│   ├── AlarmParser.swift                  # Parses "alarm: [name] <duration>" text
│   ├── AlarmSpec.swift                    # Model: alarm name + offset in seconds
│   ├── CalendarEvent.swift                # Model: calendar event with alarm specs
│   └── GoogleCalendarService.swift        # (unused by app; kept for future use)
├── Tests/CalendarAutoAlarmCoreTests/
│   └── AlarmParserTests.swift             # 29 unit tests for the alarm parser
├── CalendarAutoAlarm/                     # iOS app target
│   ├── CalendarAutoAlarmApp.swift         # @main app entry point
│   ├── ContentView.swift                  # Root view
│   ├── EventListView.swift                # Upcoming events with alarm badges
│   ├── CalendarViewModel.swift            # Fetches & holds calendar events
│   ├── AppleCalendarService.swift         # EventKit-based calendar access
│   ├── AlarmScheduler.swift               # Schedules UNUserNotification alarms
│   └── Info.plist                         # App configuration & permissions
└── CalendarAutoAlarm.xcodeproj/           # Xcode project
```

---

## Running tests (core logic only)

The alarm-parsing logic lives in a plain Swift package and can be tested on any
platform without Xcode:

```bash
swift test
```

---

## Privacy

* The app accesses your calendar **read-only** using iOS EventKit.
* Calendar data is **never** transmitted anywhere — all alarm scheduling is done
  locally using iOS notifications.
