import Foundation

/// Represents an ordered collection of `ScheduleItem`s that runs from start to finish automatically.
struct Schedule: Identifiable, Hashable, Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case note
        case items
        case createdAt
        case updatedAt
    }

    let id: UUID
    var name: String
    var note: String?
    var items: [ScheduleItem]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        note: String? = nil,
        items: [ScheduleItem],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Total runtime computed as the sum of all item durations.
    var totalDurationSeconds: Int {
        items.reduce(0) { $0 + max($1.durationSeconds, 1) }
    }

    /// Provides a version of the schedule with updated timestamps.
    func updatingTimestamps(now: Date = Date()) -> Schedule {
        Schedule(
            id: id,
            name: name,
            note: note,
            items: items,
            createdAt: createdAt,
            updatedAt: now
        )
    }

    /// Returns the running offsets for each item (cumulative seconds from start).
    var itemOffsets: [UUID: Int] {
        var offsets: [UUID: Int] = [:]
        var cumulative = 0
        for item in items {
            offsets[item.id] = cumulative
            cumulative += max(item.durationSeconds, 1)
        }
        return offsets
    }

    /// Produces a copy with items reordered.
    func reordered(items newItems: [ScheduleItem]) -> Schedule {
        Schedule(
            id: id,
            name: name,
            note: note,
            items: newItems,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
