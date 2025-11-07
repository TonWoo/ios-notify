import SwiftUI

struct ScheduleListView: View {
    @StateObject private var viewModel = ScheduleListViewModel()
    @State private var showingEditor = false
    @State private var editableSchedule: Schedule?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.schedules.isEmpty {
                    ContentUnavailableView("No Schedules", systemImage: "timer", description: Text("Create a schedule to get started."))
                } else {
                    List {
                        ForEach(viewModel.schedules) { schedule in
                            NavigationLink {
                                ScheduleDetailView(
                                    schedule: schedule,
                                    onSave: viewModel.save,
                                    onDelete: { target in
                                        viewModel.delete(schedule: target)
                                    }
                                )
                            } label: {
                                ScheduleRow(schedule: schedule)
                            }
                            .contextMenu {
                                Button("Edit") {
                                    editableSchedule = schedule
                                    showingEditor = true
                                }
                                Button("Duplicate") {
                                    viewModel.duplicate(schedule: schedule)
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editableSchedule = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Schedules")
            .sheet(isPresented: $showingEditor) {
                ScheduleEditorScene(
                    schedule: editableSchedule,
                    onSave: { viewModel.save(schedule: $0) }
                )
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { viewModel.schedules[$0] }.forEach(viewModel.delete)
    }
}

private struct ScheduleRow: View {
    let schedule: Schedule

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(schedule.name)
                .font(.headline)
            if let note = schedule.note {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Text("Total \(format(secs: schedule.totalDurationSeconds))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func format(secs: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = secs >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: TimeInterval(secs)) ?? ""
    }
}

#Preview {
    ScheduleListView()
}
