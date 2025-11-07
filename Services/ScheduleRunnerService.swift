import Foundation
import Combine
import AVFoundation
import UserNotifications

/// Drives the execution of a schedule, producing ticks each second and handling transitions.
final class ScheduleRunnerService: ObservableObject {
    enum RunnerState: Equatable {
        case idle
        case running
        case paused
        case finished
    }

    struct Tick: Equatable {
        let schedule: Schedule
        let currentItem: ScheduleItem
        let currentIndex: Int
        let elapsedInItem: Int
        let remainingInItem: Int
        let totalElapsed: Int
        let totalRemaining: Int
        let isLastItem: Bool
    }

    @Published private(set) var state: RunnerState = .idle
    let tickPublisher = PassthroughSubject<Tick, Never>()
    let completionPublisher = PassthroughSubject<Schedule, Never>()

    private var schedule: Schedule?
    private var timer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.codex.scheduleRunner")
    private var anchorStartDate: Date?
    private var accumulatedElapsed: TimeInterval = 0
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let notificationManager = NotificationManager()

    init() {
        notificationManager.requestAuthorizationIfNeeded()
    }

    // MARK: - Public API

    func start(schedule: Schedule, startDate: Date = Date()) {
        cancelTimer()
        self.schedule = schedule
        accumulatedElapsed = 0
        anchorStartDate = startDate
        state = .running
        notificationManager.scheduleNotifications(for: schedule, startingAt: startDate)
        scheduleTimer()
        emitTick(elapsedSeconds: 0)
    }

    func pause() {
        guard state == .running else { return }
        let elapsed = currentElapsedSeconds()
        accumulatedElapsed = TimeInterval(elapsed)
        anchorStartDate = nil
        cancelTimer()
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        anchorStartDate = Date().addingTimeInterval(-accumulatedElapsed)
        state = .running
        scheduleTimer()
        emitTick(elapsedSeconds: Int(accumulatedElapsed))
    }

    func skipToNext() {
        guard let schedule else { return }
        var elapsed = currentElapsedSeconds()
        let durations = schedule.items.map(\.clampedDuration)
        var cumulative = 0
        for duration in durations {
            if elapsed < cumulative + duration {
                elapsed = cumulative + duration
                break
            }
            cumulative += duration
        }
        accumulatedElapsed = TimeInterval(elapsed)
        if state == .running {
            anchorStartDate = Date().addingTimeInterval(-accumulatedElapsed)
        }
        emitTick(elapsedSeconds: elapsed)
    }

    func cancel() {
        cancelTimer()
        schedule = nil
        accumulatedElapsed = 0
        anchorStartDate = nil
        state = .idle
        notificationManager.cancelPendingNotifications()
    }

    // MARK: - Timer Handling

    private func scheduleTimer() {
        guard timer == nil else { return }
        timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(100))
        timer?.setEventHandler { [weak self] in
            guard let self else { return }
            let elapsed = self.currentElapsedSeconds()
            self.emitTick(elapsedSeconds: elapsed)
        }
        timer?.resume()
    }

    private func cancelTimer() {
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
    }

    private func currentElapsedSeconds() -> Int {
        guard let start = anchorStartDate else {
            return Int(accumulatedElapsed)
        }
        return Int(Date().timeIntervalSince(start) + accumulatedElapsed)
    }

    private func emitTick(elapsedSeconds: Int) {
        guard let schedule else { return }

        let clampElapsed = max(elapsedSeconds, 0)
        let totalDuration = schedule.totalDurationSeconds

        if clampElapsed >= totalDuration {
            DispatchQueue.main.async {
                self.state = .finished
                self.cancelTimer()
                self.playSound(for: schedule.items.last)
                self.notificationManager.cancelPendingNotifications()
                self.completionPublisher.send(schedule)
            }
            return
        }

        guard let tick = makeTick(for: schedule, elapsedSeconds: clampElapsed) else { return }

        DispatchQueue.main.async {
            self.tickPublisher.send(tick)
            self.playSoundIfNeeded(for: tick)
        }
    }

    private func makeTick(for schedule: Schedule, elapsedSeconds: Int) -> Tick? {
        var remaining = elapsedSeconds
        let items = schedule.items.enumerated()
        for (index, item) in items {
            let duration = item.clampedDuration
            if remaining < duration {
                let elapsedInItem = remaining
                let remainingInItem = duration - remaining
                let totalRemaining = schedule.totalDurationSeconds - elapsedSeconds
                let isLast = index == schedule.items.count - 1
                return Tick(
                    schedule: schedule,
                    currentItem: item,
                    currentIndex: index,
                    elapsedInItem: elapsedInItem,
                    remainingInItem: remainingInItem,
                    totalElapsed: elapsedSeconds,
                    totalRemaining: totalRemaining,
                    isLastItem: isLast
                )
            }
            remaining -= duration
        }
        return nil
    }

    // MARK: - Sound + Notifications

    private func playSoundIfNeeded(for tick: Tick) {
        // Fire when we are at the start of an item.
        guard tick.elapsedInItem == 0 else { return }
        let item = tick.currentItem
        playSound(for: item)
    }

    private func playSound(for item: ScheduleItem?) {
        guard let identifier = item?.soundIdentifier else { return }
        if let cached = audioPlayers[identifier] {
            cached.play()
            return
        }

        guard let url = Bundle.main.url(forResource: identifier, withExtension: "caf") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioPlayers[identifier] = player
            player.play()
        } catch {
            #if DEBUG
            print("Failed to play sound \(identifier): \(error)")
            #endif
        }
    }
}
