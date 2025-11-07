import Foundation
import Combine

/// Handles persistence and in-memory state for all saved schedules.
final class ScheduleStore: ObservableObject {
    @Published private(set) var schedules: [Schedule] = []
    private let fileURL: URL
    private var cancellables = Set<AnyCancellable>()

    init(filename: String = "schedules.json") {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ??
            FileManager.default.temporaryDirectory
        self.fileURL = directory.appendingPathComponent(filename)
        load()

        $schedules
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: DispatchQueue.global(qos: .background))
            .sink { [weak self] schedules in
                self?.persist(schedules)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    func refresh() {
        load()
    }

    func upsert(_ schedule: Schedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule.updatingTimestamps()
        } else {
            schedules.append(schedule.updatingTimestamps())
        }
        schedules.sort { $0.updatedAt > $1.updatedAt }
    }

    func remove(_ schedule: Schedule) {
        schedules.removeAll { $0.id == schedule.id }
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            schedules = Schedule.bootstrapSamples()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([Schedule].self, from: data)
            schedules = decoded.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            // Fallback to an empty store if decoding fails.
            schedules = []
        }
    }

    private func persist(_ schedules: [Schedule]) {
        do {
            let data = try JSONEncoder().encode(schedules)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("Failed to persist schedules: \(error)")
            #endif
        }
    }
}

// MARK: - Bootstrapping

extension Schedule {
    static func bootstrapSamples() -> [Schedule] {
        let warmup = Schedule(
            name: "Focus Sprint",
            note: "Alternating focus and breaks.",
            items: [
                ScheduleItem(label: "Warmup", durationSeconds: 60, note: "Prepare for work"),
                ScheduleItem(label: "Focus Block", durationSeconds: 1500, note: "Deep work session"),
                ScheduleItem(label: "Short Break", durationSeconds: 300),
                ScheduleItem(label: "Focus Block", durationSeconds: 1500),
                ScheduleItem(label: "Wrap-up", durationSeconds: 120)
            ]
        )

        let workout = Schedule(
            name: "Quick Workout",
            items: [
                ScheduleItem(label: "Jump Rope", durationSeconds: 180),
                ScheduleItem(label: "Rest", durationSeconds: 60),
                ScheduleItem(label: "Push-ups", durationSeconds: 120),
                ScheduleItem(label: "Plank", durationSeconds: 90),
                ScheduleItem(label: "Cooldown", durationSeconds: 120)
            ]
        )

        return [warmup, workout]
    }
}
