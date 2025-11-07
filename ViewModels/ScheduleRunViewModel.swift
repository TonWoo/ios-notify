import Foundation
import Combine

@MainActor
final class ScheduleRunViewModel: ObservableObject {
    @Published private(set) var state: ScheduleRunnerService.RunnerState = .idle
    @Published private(set) var currentTick: ScheduleRunnerService.Tick?

    let runner: ScheduleRunnerService
    private var cancellables = Set<AnyCancellable>()

    init(runner: ScheduleRunnerService = ScheduleRunnerService()) {
        self.runner = runner
        bind()
    }

    private func bind() {
        runner.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)

        runner.tickPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tick in
                self?.currentTick = tick
            }
            .store(in: &cancellables)

        runner.completionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.currentTick = nil
            }
            .store(in: &cancellables)
    }

    func start(schedule: Schedule) {
        runner.start(schedule: schedule)
    }

    func pause() {
        runner.pause()
    }

    func resume() {
        runner.resume()
    }

    func skip() {
        runner.skipToNext()
    }

    func cancel() {
        runner.cancel()
    }
}
