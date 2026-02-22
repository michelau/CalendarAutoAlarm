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

## Why it uses notifications, not Clock alarms

iOS does **not** expose any public API that allows third-party apps to create alarms in
the built-in Clock app — that alarm store is private to Apple. No third-party app
(including Google Calendar, Fantastical, or Reminders) can create Clock alarms
programmatically.

This app uses **Critical Alert notifications** instead, which behave as close to a real
alarm as iOS allows for third-party apps:

* **Sound plays even when the ringer/silent switch is off** — Critical Alerts bypass the silent switch, just like Clock alarms
* **Break through Focus modes and Do Not Disturb**
* **Stay in your notification centre** after the banner appears (not just a transient banner)

### Make notifications stay on screen like a real alarm

By default iOS shows notifications as *banners* (disappear after a few seconds).
To make them stay on screen until you dismiss them — exactly like a Clock alarm — change
the notification style to **Alerts**:

> **Settings → Notifications → Calendar Alarms → Notification Style → Alerts**

With *Alerts* selected, the notification will remain on screen, sound will play through
silent mode, and you must tap **Dismiss** (or the app) to clear it.

> **Note for App Store distribution:** The Critical Alerts entitlement requires explicit
> Apple approval for App Store submissions. Personal/development builds work without any
> special approval. Apply at:
> https://developer.apple.com/contact/request/notifications-critical-alerts-entitlement/

---

## Requirements

* Xcode 15+
* iOS 17+ device or simulator
* Calendar permission granted to the app

---

## Building & running on the iOS Simulator

### Prerequisites

* macOS 13 (Ventura) or later
* [Xcode 15](https://developer.apple.com/xcode/) or later (includes the iOS Simulator — no separate download needed)

### Steps

1. **Clone the repo**

   ```bash
   git clone https://github.com/michelau/CalendarAutoAlarm.git
   cd CalendarAutoAlarm
   ```

2. **Open in Xcode**

   ```bash
   open CalendarAutoAlarm.xcodeproj
   ```

3. **Set a signing team** *(required once — even for Simulator)*  
   1. In the Project Navigator click **CalendarAutoAlarm** (the project, not a folder).
   2. Select the **CalendarAutoAlarm** target → *Signing & Capabilities* tab.
   3. Under *Team*, choose your Apple ID from the dropdown.
      Add it first via *Xcode → Settings → Accounts* if it isn't listed.

4. **Select a simulator**  
   In the Xcode toolbar, click the scheme/destination selector (next to the Run button) and choose
   an iPhone simulator — e.g. **iPhone 16 (iOS 18.x)**.

5. **Build and run** — press **⌘R** (or *Product → Run*).  
   The Simulator will launch and the app will open automatically.

6. **Grant Calendar access** when the permission dialog appears.  
   If you dismiss it accidentally, re-enable access in  
   *Simulator → Settings → Privacy & Security → Calendars → CalendarAutoAlarm*.

#### Adding test calendar events in the Simulator

The Simulator has its own isolated calendar store.  
To test `alarm:` directives without a physical device:

1. In the Simulator, open the **Calendar** app.
2. Tap a day and create a new event (e.g. "Morning stand-up").
3. In the **Notes** field add an alarm directive such as `alarm: wakeup 15m`.
4. Save the event, then return to CalendarAutoAlarm and pull down to refresh.

#### Command-line build (optional)

```bash
# List available simulators
xcrun simctl list devices available

# Build for a specific simulator
xcodebuild \
  -project CalendarAutoAlarm.xcodeproj \
  -scheme CalendarAutoAlarm \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug \
  build

# Run the core-logic unit tests without Xcode (works on Linux/CI too)
swift test
```

---

## Installing & running on iPhone

### Prerequisites

* An iPhone running **iOS 17 or later**
* A Mac with **Xcode 15+**
* A USB or USB-C cable to connect the iPhone to the Mac
* An **Apple ID** (a free personal Apple ID is enough for 7-day sideloading;
  an [Apple Developer Program](https://developer.apple.com/programs/) membership
  ($99/year) removes the 7-day expiry and allows distribution via TestFlight or the App Store)

### Steps

1. **Connect your iPhone** to the Mac with a cable.  
   Unlock the phone and tap **Trust** if a "Trust This Computer?" dialog appears.

2. **Open the project in Xcode**

   ```bash
   open CalendarAutoAlarm.xcodeproj
   ```

3. **Select your iPhone as the destination**  
   In the Xcode toolbar click the destination selector and choose your device
   (e.g. *"John's iPhone"*).  
   If the device shows as "not connected", make sure USB trust is accepted and the
   phone is unlocked, then wait a few seconds for Xcode to recognize it.

4. **Set a signing team**
   1. In the Project Navigator click **CalendarAutoAlarm** (the project, not a folder).
   2. Select the **CalendarAutoAlarm** target → *Signing & Capabilities* tab.
   3. Under *Team*, choose your Apple ID (add it via *Xcode → Settings → Accounts* if it
      isn't listed yet).
   4. Xcode will automatically generate a provisioning profile.  
      If you see a bundle-ID conflict, change *Bundle Identifier* to something unique,
      e.g. `com.yourname.CalendarAutoAlarm`.

5. **Build and install** — press **⌘R**.  
   Xcode compiles the app and installs it on the device.

6. **Trust the developer certificate on-device** *(free Apple ID only)*  
   The first time you open the app you may see *"Untrusted Developer"*.
   Fix this once:
   > **Settings → General → VPN & Device Management → [Your Apple ID] → Trust**

7. **Grant Calendar access** when the app asks on first launch.  
   You can review or change this later at  
   *Settings → Privacy & Security → Calendars → CalendarAutoAlarm*.

8. **Add alarm directives to an event**  
   In the iPhone **Calendar** app (or Google Calendar app), open any event,
   edit its **Notes/Description** field, and add a line such as `alarm: wakeup 30m`.
   Save, then open CalendarAutoAlarm and pull down to refresh — the alarm will be
   scheduled as a local notification.

> **Using Google Calendar on iPhone?**  
> Add your Google account in **Settings → Calendar → Accounts → Add Account → Google**.
> Its events will appear in the on-device calendar store and become visible to this app.

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
