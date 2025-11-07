import SwiftUI

struct ScheduleRunView: View {
    @StateObject private var viewModel = ScheduleRunViewModel()
    let schedule: Schedule

    var body: some View {
        VStack(spacing: 24) {
            if let tick = viewModel.currentTick {
                ProgressView(value: progress(tick: tick))
                    .progressViewStyle(.circular)
                    .scaleEffect(2)

                VStack(spacing: 8) {
                    Text(tick.currentItem.label)
                        .font(.title)
                        .bold()
                    Text("Remaining: \(format(seconds: tick.remainingInItem))")
                        .font(.headline)
                    if !tick.isLastItem {
                        Text("Next: \(nextLabel(for: tick))")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("Ready to run \(schedule.name)")
                    .font(.title2)
            }

            HStack(spacing: 16) {
                Button(action: startOrResume) {
                    Label(state == .running ? "Pause" : "Start", systemImage: state == .running ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button("Skip") {
                    viewModel.skip()
                }
                .disabled(state != .running)

                Button("Cancel") {
                    viewModel.cancel()
                }
                .disabled(state == .idle)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.start(schedule: schedule)
        }
    }

    private var state: ScheduleRunnerService.RunnerState {
        viewModel.state
    }

    private func startOrResume() {
        switch state {
        case .running:
            viewModel.pause()
        case .paused:
            viewModel.resume()
        case .idle, .finished:
            viewModel.start(schedule: schedule)
        }
    }

    private func progress(tick: ScheduleRunnerService.Tick) -> Double {
        let total = Double(tick.schedule.totalDurationSeconds)
        guard total > 0 else { return 0 }
        return Double(tick.totalElapsed) / total
    }

    private func format(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }

    private func nextLabel(for tick: ScheduleRunnerService.Tick) -> String {
        let nextIndex = tick.currentIndex + 1
        guard nextIndex < tick.schedule.items.count else { return "Done" }
        return tick.schedule.items[nextIndex].label
    }
}

#Preview {
    if let schedule = Schedule.bootstrapSamples().first {
        ScheduleRunView(schedule: schedule)
    }
}
