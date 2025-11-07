import SwiftUI

struct ScheduleEditorScene: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ScheduleEditorViewModel
    let onSave: (Schedule) -> Void

    init(schedule: Schedule?, onSave: @escaping (Schedule) -> Void) {
        _viewModel = StateObject(wrappedValue: ScheduleEditorViewModel(schedule: schedule))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Name", text: $viewModel.name)
                    TextField("Note", text: $viewModel.note, axis: .vertical)
                }

                Section("Items (\(viewModel.items.count))") {
                    ForEach(viewModel.items) { item in
                        ScheduleItemEditorRow(item: item, viewModel: viewModel)
                    }
                    .onMove(perform: viewModel.moveItem)
                    .onDelete { indexSet in
                        indexSet.map { viewModel.items[$0] }.forEach(viewModel.removeItem)
                    }

                    Button {
                        viewModel.addItem()
                    } label: {
                        Label("Add Segment", systemImage: "plus.circle")
                    }
                }

                Section("Preview") {
                    Text("Total: \(format(seconds: viewModel.totalDuration))")
                        .font(.headline)
                }

                if !viewModel.validationErrors.isEmpty {
                    Section("Errors") {
                        ForEach(viewModel.validationErrors, id: \.self) { message in
                            Text(message).foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Edit Schedule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("Schedule Editor")
                        .font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        guard let schedule = viewModel.buildSchedule() else { return }
        onSave(schedule)
        dismiss()
    }

    private func format(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(seconds)) ?? ""
    }
}

private struct ScheduleItemEditorRow: View {
    @State private var label: String
    @State private var duration: Double
    @State private var note: String
    let item: ScheduleItem
    let viewModel: ScheduleEditorViewModel

    init(item: ScheduleItem, viewModel: ScheduleEditorViewModel) {
        self.item = item
        self.viewModel = viewModel
        _label = State(initialValue: item.label)
        _duration = State(initialValue: Double(item.durationSeconds))
        _note = State(initialValue: item.note ?? "")
    }

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Label", text: $label)
            HStack {
                Text("Duration \(Int(duration))s")
                Slider(value: Binding(
                    get: { duration },
                    set: { newValue in
                        duration = newValue
                        commit()
                    }
                ), in: 1...3600)
            }
            TextField("Note", text: $note)
            Button("Add 30s Gap After") {
                viewModel.addGap(of: 30, after: item)
            }
            .buttonStyle(.borderedProminent)
        }
        .onDisappear(perform: commit)
    }

    private func commit() {
        viewModel.updateItem(
            item,
            label: label,
            durationSeconds: Int(duration),
            note: note.isEmpty ? nil : note,
            soundIdentifier: item.soundIdentifier
        )
    }
}

#Preview {
    ScheduleEditorScene(schedule: nil) { _ in }
}
