import Foundation

/// Represents a single segment in a user-defined schedule.
struct ScheduleItem: Identifiable, Hashable, Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case label
        case durationSeconds
        case note
        case soundIdentifier
    }

    let id: UUID
    var label: String
    var durationSeconds: Int
    var note: String?
    var soundIdentifier: String?

    init(
        id: UUID = UUID(),
        label: String,
        durationSeconds: Int,
        note: String? = nil,
        soundIdentifier: String? = nil
    ) {
        self.id = id
        self.label = label
        self.durationSeconds = durationSeconds
        self.note = note
        self.soundIdentifier = soundIdentifier
    }

    /// Returns the duration formatted as mm:ss, ensuring a minimum of seconds precision.
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = durationSeconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(durationSeconds)) ?? "0:00"
    }

    /// Provides a safe duration, ensuring a minimum of 1 second to avoid zero-length segments.
    var clampedDuration: Int {
        max(durationSeconds, 1)
    }

    /// Builds a copy with a different duration.
    func withDuration(_ newDuration: Int) -> ScheduleItem {
        ScheduleItem(
            id: id,
            label: label,
            durationSeconds: newDuration,
            note: note,
            soundIdentifier: soundIdentifier
        )
    }
}
