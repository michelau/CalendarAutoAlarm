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

This app uses **local notifications** instead:

* **Play the device's ringtone sound** (louder and more attention-grabbing than a ping)
* **Mirror automatically to a paired Apple Watch** (haptic + sound, no Watch app needed)
* **Stay in your notification centre** after the banner appears

> **Focus modes / Do Not Disturb:**  
> Without a paid Apple Developer Program membership, the "Time Sensitive Notifications"
> capability is unavailable (personal teams don't support it). This means alarms will be
> suppressed by Focus modes and Do Not Disturb just like any other notification.  
> **Workaround:** disable Focus mode, or add *Calendar Alarms* to your Focus's allowed
> apps under **Settings → Focus → [your focus] → Allowed Notifications**.

> **Silent/ringer switch:**  
> Notifications do not bypass the silent switch. Keep your phone on ring mode for alarms
> you care about.

### Make notifications stay on screen like a real alarm

By default iOS shows notifications as *banners* (disappear after a few seconds).
To make them stay on screen until you dismiss them — like a Clock alarm — change the
notification style to **Alerts**:

> **Settings → Notifications → Calendar Alarms → Notification Style → Alerts**

With *Alerts* selected the notification remains on screen and requires a tap to dismiss.

---

## Apple Watch — custom haptic pattern

The companion Watch app (`CalendarAlarmsWatch` target, inside the same Xcode project)
intercepts alarm notifications on the Watch and plays a **custom haptic sequence**
instead of the standard single buzz.

Tested on **Apple Watch Series 7** (watchOS 26.3).

> **Architecture note:** The Watch app is a separate *target* within
> `CalendarAutoAlarm.xcodeproj` — not a separate `.xcodeproj`.  The Watch bundle
> is embedded inside the iOS app bundle at build time.

### The "3 · 1 · 2" alarm haptic

The pattern is designed to be unmistakably distinct from every other Watch haptic:

```
tap  tap  tap  ·····  THUD  ·  tap  tap
0.0  0.2  0.4         1.2      1.9  2.1  (seconds)
```

- **Three quick taps** — announces the alarm
- **One firm thud** (`success` haptic) — the signature beat; no other iOS notification uses this shape
- **Two closing taps** — confirms the sequence is done

The "3-thud-2" rhythm is easy to learn within a few days — the same way people quickly
learn to distinguish a phone-call buzz from a text-message buzz.

### How to install the Watch app

> ⚠️ **Do NOT select the `CalendarAlarmsWatch` scheme and run it directly.**  
> Running the Watch scheme alone bypasses the companion relationship and causes
> code-signing failures with personal/free Apple ID teams.

**The correct workflow — one step deploys both apps:**

1. Make sure your iPhone is connected and your Apple Watch is paired and nearby.
2. In the Xcode toolbar, select the **`CalendarAutoAlarm`** scheme (the iOS app).
3. Set the **destination** to your **iPhone** (not the Watch).
4. Press **⌘R**.

Xcode builds the iOS app, embeds the Watch app inside it, and automatically pushes
the Watch companion to your paired Apple Watch in the same run operation. You will
see both apps appear on their respective devices.

### Verifying the Watch app is installed and working

**Step 1 — Confirm the app appears on your Watch:**

1. On your iPhone, open the **Watch** app.
2. Scroll down to **Installed on Apple Watch**.
3. Look for **Calendar Alarms** in the list.  
   If it isn't there, run ⌘R from Xcode again (iOS scheme → iPhone destination) and wait
   for the spinner in the Watch app to finish syncing.

**Step 2 — Test the haptic from the Watch:**

1. On the Watch, press the **Digital Crown** to open the app grid.
2. Find and tap **Calendar Alarms** (yellow bell icon).
3. Tap the **"Test Haptic"** button.  
   You should feel the "3-thud-2" vibration sequence immediately.

If you feel nothing, the Watch app isn't running or haptics are disabled
(check **Watch → Settings → Sounds & Haptics → Haptic Alerts**).

---

### When does the Watch vibrate for alarms?

> **Key rule: the Watch only receives notifications when your iPhone screen is
> locked/off.**
>
> If your iPhone is unlocked and active when an alarm fires, iOS delivers the
> notification to the iPhone only — the Watch does NOT vibrate. This is standard
> iOS/watchOS behaviour that applies to all apps, not just this one.

**To reliably get Watch haptics from your alarms:**

- **Lock your iPhone** before the alarm fire time.  
  Press the side button to lock it, then wear your Watch normally.
- Or put the iPhone face-down (auto-lock applies).
- Or enable **Wrist Detection** on the Watch: Watch app → Passcode → Wrist Detection ON.
  With wrist detection on, notifications go to Watch when it's on your wrist even if
  iPhone is nearby.

> **Foreground vs background:** The custom "3·1·2" haptic pattern only plays when you
> have the Calendar Alarms Watch app **open on screen** at the moment the alarm fires.
> When the Watch app is in the background (normal use case — Watch is on your wrist,
> screen off) the system delivers the notification with the **standard Watch haptic buzz**
> automatically. Both cases work; only the foreground case uses the custom pattern.

---

### Trusting the developer certificate on Watch (free Apple ID)

With a free personal Apple ID, watchOS requires a separate trust step beyond the
iPhone trust:

1. On your **iPhone**, open the **Watch** app.
2. Go to **General → Device Management**.
3. Tap your Apple ID → **Trust**.

*(This menu only appears after the Watch app bundle has been installed at least once —
i.e. after running ⌘R with the iOS scheme at least once.)*

If "Device Management" is not visible in the Watch app, restart both the iPhone and
Apple Watch, then run ⌘R again from Xcode.

---

## Requirements

* Xcode 26+
* iOS 26+ iPhone
* watchOS 26+ Apple Watch (companion Watch app, optional — tested on Series 7)
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

* An iPhone running **iOS 26 or later**
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
│   ├── AlarmParserTests.swift             # 29 unit tests for the alarm parser
│   └── EventRelevanceTests.swift          # 10 unit tests for event filtering
├── CalendarAutoAlarm/                     # iOS app target
│   ├── CalendarAutoAlarmApp.swift         # @main app entry point
│   ├── ContentView.swift                  # Root view
│   ├── EventListView.swift                # Upcoming events with alarm rows
│   ├── CalendarViewModel.swift            # Fetches & holds calendar events
│   ├── AppleCalendarService.swift         # EventKit-based calendar access + relevance filter
│   ├── AlarmScheduler.swift               # Schedules UNUserNotification alarms
│   └── Info.plist                         # App configuration & permissions
├── CalendarAlarmsWatch/                   # watchOS companion app target (Series 7+)
│   ├── CalendarAlarmsWatchApp.swift       # @main Watch app + notification delegate
│   ├── HapticManager.swift                # Custom "3·1·2" haptic pattern
│   └── Info.plist                         # Watch app configuration
└── CalendarAutoAlarm.xcodeproj/           # Xcode project (both targets)
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

---

## Troubleshooting

### "Personal development teams do not support the Time Sensitive Notifications capability"

This error means Xcode is using a **stale build cache** from a previous version of the
project that briefly included the `time-sensitive` entitlement. That entitlement has since
been removed from the repo entirely (personal/free Apple ID teams cannot use it).

**Fix — two steps:**

1. Make sure you have the latest code:

   ```bash
   git pull
   ```

2. In Xcode, clean the build folder to discard the stale cache:

   **Product → Clean Build Folder** (⌘⇧K)

Then press **⌘R** to build and run. The error will not reappear.

### "Entitlement `com.apple.developer.usernotifications.critical-alerts` requires Apple approval"

Same fix as above — `git pull` then **Product → Clean Build Folder** (⌘⇧K).  
Both the `critical-alerts` and `time-sensitive` entitlements have been removed from the
project. If Xcode still shows this, the build cache still has a stale copy.

### "Signing for CalendarAutoAlarm requires a development team"

Open the project in Xcode, select the **CalendarAutoAlarm** target →
*Signing & Capabilities* tab → set **Team** to your Apple ID.  
If your Apple ID isn't listed, add it via *Xcode → Settings → Accounts*.

### "Could not get trait set for device Watch6,9 with version 26.3"

This is a **benign warning** from `actool` in Xcode 26 beta — the SDK doesn't yet
include trait-set data for Watch6,9 at watchOS 26.3. It does not affect the build
or runtime behaviour and can be safely ignored.

### "CalendarAlarmsWatch failed to launch" / Watch app exits immediately

**First — check you are using the correct workflow:**

> Select the **`CalendarAutoAlarm`** (iOS) scheme → set destination to your **iPhone** → press **⌘R**.  
> Do **not** select the `CalendarAlarmsWatch` scheme and run it separately.  
> Running the Watch scheme alone bypasses companion-app signing and causes this error.

If you already used the iOS scheme and the Watch app still fails, the cause is almost
always that the developer certificate hasn't been trusted on the Watch yet:

1. **Trust on iPhone first** (if you haven't already):  
   *Settings → General → VPN & Device Management → \[Your Apple ID\] → Trust*

2. **Trust on Watch** — watchOS needs a separate trust step:  
   On your iPhone open the **Watch** app → *General → Device Management* →  
   tap your Apple ID → **Trust**.  
   *(This menu only appears after the Watch app bundle has been installed at least once.)*

3. **Clean build folder** (⌘⇧K) and press **⌘R** again with the iOS scheme.

If the Watch app still fails after trusting, restart both the iPhone and Apple Watch,
then run ⌘R again from Xcode.

