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

    static func playAlarmPattern() {
        // — Triple tap —
        play(.notification, after: 0.00)
        play(.notification, after: 0.20)
        play(.notification, after: 0.40)

        // — Signature thud (long pause + success) —
        play(.success,      after: 1.20)

        // — Closing pair —
        play(.notification, after: 1.90)
        play(.notification, after: 2.10)
    }

    // MARK: - Private

    private static func play(_ type: WKHapticType, after delay: TimeInterval) {
        if delay == 0 {
            WKInterfaceDevice.current().play(type)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                WKInterfaceDevice.current().play(type)
            }
        }
    }
}
