import WatchKit

/// Plays a distinctive haptic sequence on Apple Watch when a calendar alarm fires.
///
/// ## Pattern: "3 · 1 · 2"
///
/// ```
/// tap tap tap  ···  THUD  ·  tap tap
/// 0   0.2 0.4       1.2      1.9 2.1
/// ```
///
/// - **Three quick taps** (`.notification`) announce the alarm.
/// - **A single firm thud** (`.success`) is the signature beat that makes this pattern
///   unmistakable — unlike message/call/notification haptics which never have this shape.
/// - **Two closing taps** (`.notification`) confirm the pattern is complete.
///
/// The brain can learn "3-thud-2 = calendar alarm" in under a week of use, the same way
/// people learn to distinguish phone-ring vibration from text-message vibration.
enum HapticManager {

    /// Plays the alarm haptic pattern asynchronously.
    ///
    /// Uses `Task.sleep` (Swift cooperative threading) instead of
    /// `DispatchQueue.main.asyncAfter` so the full sequence completes reliably
    /// inside a `WKUserNotificationHostingController.didReceive()` call — the
    /// main run loop's timer queue is not driven reliably in that context, but
    /// the Swift concurrency runtime is.
    @MainActor
    static func playAlarmPattern() async {
        // Each step: (haptic type, nanoseconds to sleep *before* this tap)
        let steps: [(WKHapticType, UInt64)] = [
            (.notification,     0),           // t = 0.0 s
            (.notification,  200_000_000),    // t = 0.2 s
            (.notification,  200_000_000),    // t = 0.4 s
            (.success,       800_000_000),    // t = 1.2 s  — signature thud
            (.notification,  700_000_000),    // t = 1.9 s
            (.notification,  200_000_000),    // t = 2.1 s
        ]

        for (type, delay) in steps {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            WKInterfaceDevice.current().play(type)
        }
    }
}
