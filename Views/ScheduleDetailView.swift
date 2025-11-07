import SwiftUI

struct ScheduleDetailView: View {
    @State private var presentingRunner = false
    @State private var presentingEditor = false
    @State private var editableSchedule: Schedule
    let onSave: (Schedule) -> Void
    let onDelete: (Schedule) -> Void

    init(schedule: Schedule, onSave: @escaping (Schedule) -> Void, onDelete: @escaping (Schedule) -> Void) {
        _editableSchedule = State(initialValue: schedule)
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        List {
            Section {
                Text(editableSchedule.note ?? "No notes")
                Text("Total duration \(format(seconds: editableSchedule.totalDurationSeconds))")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Overview")
            }

            Section("Segments") {
                ForEach(Array(editableSchedule.items.enumerated()), id: \.element.id) { element in
                    let index = element.offset + 1
                    let item = element.element
                    VStack(alignment: .leading) {
                        Text("\(index). \(item.label)")
                        Text("\(item.formattedDuration)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let note = item.note {
                            Text(note).font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle(editableSchedule.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { presentingEditor = true }
            }
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    onDelete(editableSchedule)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                presentingRunner = true
            } label: {
                Label("Run Schedule", systemImage: "play.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .sheet(isPresented: $presentingRunner) {
            ScheduleRunView(schedule: editableSchedule)
        }
        .sheet(isPresented: $presentingEditor) {
            ScheduleEditorScene(schedule: editableSchedule) { updated in
                editableSchedule = updated
                onSave(updated)
            }
        }
    }

    private func format(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }
}

#Preview {
    if let schedule = Schedule.bootstrapSamples().first {
        NavigationStack {
            ScheduleDetailView(schedule: schedule, onSave: { _ in }, onDelete: { _ in })
        }
    }
}
