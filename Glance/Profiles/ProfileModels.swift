import Foundation

struct Profile: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var presetName: String?
    var formationName: String?
    var trigger: ProfileTrigger

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }
}

struct ProfileTrigger: Codable, Equatable {
    /// Frontmost app names that activate this profile (e.g. ["Xcode", "Terminal"]).
    var apps: [String]?
    /// Time range in "HH:mm-HH:mm" format (e.g. "18:00-06:00" for evening).
    var timeRange: String?

    var isEmpty: Bool {
        (apps ?? []).isEmpty && timeRange == nil
    }

    /// Check if the given app name matches this trigger.
    func matchesApp(_ appName: String) -> Bool {
        guard let apps, !apps.isEmpty else { return false }
        return apps.contains { $0.localizedCaseInsensitiveCompare(appName) == .orderedSame }
    }

    /// Check if the current time falls within the time range.
    func matchesCurrentTime() -> Bool {
        guard let timeRange, !timeRange.isEmpty else { return false }
        let parts = timeRange.split(separator: "-")
        guard parts.count == 2 else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: String(parts[0])),
              let end = formatter.date(from: String(parts[1]))
        else { return false }

        let calendar = Calendar.current
        let now = Date()
        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let startMinutes = calendar.component(.hour, from: start) * 60 + calendar.component(.minute, from: start)
        let endMinutes = calendar.component(.hour, from: end) * 60 + calendar.component(.minute, from: end)

        if startMinutes <= endMinutes {
            // Same-day range: 09:00-17:00
            return nowMinutes >= startMinutes && nowMinutes < endMinutes
        } else {
            // Overnight range: 18:00-06:00
            return nowMinutes >= startMinutes || nowMinutes < endMinutes
        }
    }
}
