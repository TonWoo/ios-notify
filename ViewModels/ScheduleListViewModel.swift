import Foundation
import Combine

@MainActor
final class ScheduleListViewModel: ObservableObject {
    @Published private(set) var schedules: [Schedule] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let store: ScheduleStore
    private var cancellables = Set<AnyCancellable>()

    init(store: ScheduleStore = ScheduleStore()) {
        self.store = store
        bind()
    }

    private func bind() {
        store.$schedules
            .receive(on: DispatchQueue.main)
            .sink { [weak self] schedules in
                self?.schedules = schedules
            }
            .store(in: &cancellables)
    }

    func refresh() {
        isLoading = true
        Task {
            store.refresh()
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func duplicate(schedule: Schedule) {
        let copy = Schedule(
            name: "\(schedule.name) Copy",
            note: schedule.note,
            items: schedule.items
        )
        store.upsert(copy)
    }

    func delete(schedule: Schedule) {
        store.remove(schedule)
    }

    func save(schedule: Schedule) {
        store.upsert(schedule)
    }
}
