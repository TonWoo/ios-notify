import Foundation

@MainActor
final class ScheduleEditorViewModel: ObservableObject {
    @Published var name: String
    @Published var note: String
    @Published var items: [ScheduleItem]
    @Published var validationErrors: [String] = []

    private let originalSchedule: Schedule?

    init(schedule: Schedule? = nil) {
        self.originalSchedule = schedule
        if let schedule {
            self.name = schedule.name
            self.note = schedule.note ?? ""
            self.items = schedule.items
        } else {
            self.name = "New Schedule"
            self.note = ""
            self.items = [
                ScheduleItem(label: "Segment 1", durationSeconds: 60),
                ScheduleItem(label: "Break", durationSeconds: 15)
            ]
        }
    }

    var totalDuration: Int {
        items.reduce(0) { $0 + $1.clampedDuration }
    }

    func addItem(after item: ScheduleItem? = nil) {
        let newItem = ScheduleItem(label: "New Segment", durationSeconds: 60)
        if let item, let index = items.firstIndex(where: { $0.id == item.id }) {
            items.insert(newItem, at: index + 1)
        } else {
            items.append(newItem)
        }
    }

    func addGap(of seconds: Int = 30, after item: ScheduleItem? = nil) {
        let gap = ScheduleItem(label: "Gap", durationSeconds: seconds)
        addItemAfter(item, newItem: gap)
    }

    func removeItem(_ item: ScheduleItem) {
        items.removeAll { $0.id == item.id }
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    func updateItem(_ item: ScheduleItem, label: String, durationSeconds: Int, note: String?, soundIdentifier: String?) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = ScheduleItem(
            id: item.id,
            label: label,
            durationSeconds: max(1, durationSeconds),
            note: note,
            soundIdentifier: soundIdentifier
        )
    }

    func buildSchedule() -> Schedule? {
        validationErrors = validate()
        guard validationErrors.isEmpty else { return nil }

        let schedule = Schedule(
            id: originalSchedule?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.isEmpty ? nil : note,
            items: items.map { item in
                ScheduleItem(
                    id: item.id,
                    label: item.label.trimmingCharacters(in: .whitespacesAndNewlines),
                    durationSeconds: item.clampedDuration,
                    note: item.note,
                    soundIdentifier: item.soundIdentifier
                )
            },
            createdAt: originalSchedule?.createdAt ?? Date(),
            updatedAt: Date()
        )
        return schedule
    }

    private func validate() -> [String] {
        var errors: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Name cannot be empty.")
        }
        if items.isEmpty {
            errors.append("Add at least one schedule item.")
        }
        if items.contains(where: { $0.clampedDuration < 1 }) {
            errors.append("Item duration must be at least 1 second.")
        }
        return errors
    }

    private func addItemAfter(_ item: ScheduleItem?, newItem: ScheduleItem) {
        if let item, let index = items.firstIndex(where: { $0.id == item.id }) {
            items.insert(newItem, at: index + 1)
        } else {
            items.append(newItem)
        }
    }
}
