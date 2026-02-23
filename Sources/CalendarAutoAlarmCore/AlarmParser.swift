import Foundation

/// Parses alarm specifications from calendar event description text.
///
/// ## Alarm Format
///
/// Each alarm directive occupies its own line (or appears inline) and follows this pattern:
///
/// ```
/// alarm: [name] <duration>
/// ```
///
/// | Example text          | Result                                        |
/// |-----------------------|-----------------------------------------------|
/// | `alarm: 5m`           | 5 minutes before, no name                     |
/// | `alarm: 1h`           | 1 hour before, no name                        |
/// | `alarm: 1h30m`        | 1 hour 30 minutes before, no name             |
/// | `alarm: 30s`          | 30 seconds before, no name                    |
/// | `alarm: 0`            | At event start time, no name                  |
/// | `alarm: wakeup 30m`   | 30 minutes before, named "wakeup"             |
/// | `alarm: morning 1h`   | 1 hour before, named "morning"                |
///
/// Multiple alarms may appear in the same description, one per line.
/// The keyword `alarm:` is case-insensitive.
public struct AlarmParser: Sendable {

    public init() {}

    // MARK: - Public API

    /// Parses all alarm specs from an event description string.
    ///
    /// - Parameter description: The full description text of a calendar event.
    /// - Returns: An array of ``AlarmSpec`` values found in the description,
    ///   in the order they appear. Returns an empty array if none are found.
    public func parse(description: String) -> [AlarmSpec] {
        description
            .components(separatedBy: .newlines)
            .compactMap { parseLine($0) }
    }

    // MARK: - Internal (visible for testing)

    /// Parses a duration string (e.g. `"5m"`, `"1h30m"`, `"0"`) into a number of seconds.
    ///
    /// Supported unit suffixes: `h` (hours), `m` (minutes), `s` (seconds).
    /// The special value `"0"` means zero seconds (alarm at event start).
    ///
    /// Returns `nil` for strings that are not valid durations.
    func parseDuration(_ string: String) -> Int? {
        let s = string.lowercased()

        // Special-case: "0" → at event time
        if s == "0" { return 0 }

        // Must consist only of digits and known unit characters
        guard s.allSatisfy({ $0.isNumber || "hms".contains($0) }) else { return nil }
        // Must contain at least one unit character
        guard s.contains(where: { "hms".contains($0) }) else { return nil }

        var total = 0
        var currentDigits = ""

        for char in s {
            if char.isNumber {
                currentDigits.append(char)
            } else if let multiplier = unitMultiplier(char) {
                guard !currentDigits.isEmpty, let value = Int(currentDigits) else { return nil }
                total += value * multiplier
                currentDigits = ""
            } else {
                return nil
            }
        }

        // Trailing digits without a unit are invalid (e.g. "1h30")
        guard currentDigits.isEmpty else { return nil }

        return total
    }

    // MARK: - Private

    private func parseLine(_ line: String) -> AlarmSpec? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let colonRange = trimmed.range(of: "alarm:", options: .caseInsensitive) else {
            return nil
        }
        let content = String(trimmed[colonRange.upperBound...])
            .trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return nil }
        return parseAlarmContent(content)
    }

    private func parseAlarmContent(_ text: String) -> AlarmSpec? {
        let parts = text
            .split(separator: " ", omittingEmptySubsequences: true)
            .map(String.init)
        guard !parts.isEmpty else { return nil }

        // The last token should be the duration; everything before it is the name.
        if let seconds = parseDuration(parts.last!) {
            let name = parts.count > 1 ? parts.dropLast().joined(separator: " ") : nil
            return AlarmSpec(name: name, offsetBeforeEventSeconds: seconds)
        }

        // Fallback: try to parse the entire content as a bare duration (handles "0" alone)
        if let seconds = parseDuration(text.trimmingCharacters(in: .whitespaces)) {
            return AlarmSpec(name: nil, offsetBeforeEventSeconds: seconds)
        }

        return nil
    }

    private func unitMultiplier(_ c: Character) -> Int? {
        switch c {
        case "h": return 3600
        case "m": return 60
        case "s": return 1
        default:  return nil
        }
    }
}
