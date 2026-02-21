# CalendarAutoAlarm

An iPhone app that automatically schedules named alarms for events in your Google Calendar
whenever those events contain a special alarm directive in their description field.

---

## How it works

Add an `alarm:` line to the **description** of any Google Calendar event:

| Description text         | Effect                                               |
|--------------------------|------------------------------------------------------|
| `alarm: 5m`              | Alarm notification **5 minutes** before the event   |
| `alarm: 1h`              | Alarm notification **1 hour** before the event       |
| `alarm: 1h30m`           | Alarm notification **1 hour 30 minutes** before      |
| `alarm: 30s`             | Alarm notification **30 seconds** before             |
| `alarm: 0`               | Alarm notification **at event start time**           |
| `alarm: wakeup 30m`      | Alarm named **"wakeup"**, 30 minutes before          |
| `alarm: morning 1h`      | Alarm named **"morning"**, 1 hour before             |

Multiple `alarm:` lines in the same description create multiple alarms.  
The keyword `alarm:` is **case-insensitive**.

The app checks the next 7 days of your calendar and schedules a local iOS notification
for each alarm it finds. Pull-to-refresh or the ↺ button re-syncs at any time.

---

## Requirements

* Xcode 15+  
* iOS 16+ device or simulator  
* A Google account with Google Calendar  
* A Google Cloud project with the **Google Calendar API** enabled

---

## Setup

### 1. Google Cloud / OAuth configuration

1. Open [Google Cloud Console](https://console.cloud.google.com) and create (or select) a project.
2. Enable **Google Calendar API** under *APIs & Services → Library*.
3. Go to *APIs & Services → Credentials* and click **Create credentials → OAuth client ID**.
4. Select **iOS** as the application type and enter your bundle identifier
   (default: `com.example.CalendarAutoAlarm`).
5. Copy the generated **Client ID** (looks like `123456789-abc123.apps.googleusercontent.com`).

### 2. Configure the app

Open `CalendarAutoAlarm/Info.plist` and replace both occurrences of
`YOUR_GOOGLE_OAUTH_CLIENT_ID` with the client ID from step 5:

```xml
<key>GoogleOAuthClientID</key>
<string>123456789-abc123.apps.googleusercontent.com</string>

<!-- in CFBundleURLSchemes -->
<string>com.googleusercontent.apps.123456789-abc123</string>
```

> **Note:** The URL scheme is the *reverse* of the client ID with
> `com.googleusercontent.apps.` as the prefix, which Google Cloud generates for you.

### 3. Build & run

Open `CalendarAutoAlarm.xcodeproj` in Xcode, select your device or simulator, and press **Run (⌘R)**.

---

## Project structure

```
CalendarAutoAlarm/
├── Package.swift                          # Swift Package – core library + tests
├── Sources/CalendarAutoAlarmCore/
│   ├── AlarmParser.swift                  # Parses "alarm: [name] <duration>" text
│   ├── AlarmSpec.swift                    # Model: alarm name + offset in seconds
│   ├── CalendarEvent.swift                # Model: calendar event with alarm specs
│   └── GoogleCalendarService.swift        # Google Calendar REST API client
├── Tests/CalendarAutoAlarmCoreTests/
│   └── AlarmParserTests.swift             # 29 unit tests for the alarm parser
├── CalendarAutoAlarm/                     # iOS app target
│   ├── CalendarAutoAlarmApp.swift         # @main app entry point
│   ├── ContentView.swift                  # Root view (sign-in or event list)
│   ├── SignInView.swift                   # Google sign-in screen
│   ├── EventListView.swift                # Upcoming events with alarm badges
│   ├── CalendarViewModel.swift            # Fetches & holds calendar events
│   ├── AuthManager.swift                  # OAuth 2.0 sign-in / token storage
│   ├── AlarmScheduler.swift               # Schedules UNUserNotification alarms
│   └── Info.plist                         # App configuration & URL schemes
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

* The app requests **read-only** access to your Google Calendar
  (`https://www.googleapis.com/auth/calendar.readonly`).
* Calendar data is **never** sent anywhere other than Google's own API.
* Your OAuth access token is stored in the iOS Keychain.
