## ios_notify Prototype

This directory snapshot is a starting point for the relative-timer app discussed with the assistant. It is **not** a complete Xcode project yet, but it contains the core Swift source scaffolding so you can drag these files into a fresh SwiftUI project and iterate quickly.

### Structure

- `App/IOSNotifyApp.swift` — SwiftUI application entry point, launches the schedule list.
- `Models/` — Data models (`Schedule`, `ScheduleItem`) with helpers for offsets, formatting, and sample content.
- `Support/ScheduleStore.swift` — Lightweight persistence layer using `Codable` + `FileManager`.
- `Services/` — Runtime services: `ScheduleRunnerService` (timer driver) and `NotificationManager`.
- `ViewModels/` — MVVM state holders for list, editor, and run flows.
- `Views/` — SwiftUI scenes for listing, editing, running schedules, plus a detail screen.

### Getting Started

1. Create a new **App** project in Xcode using Swift + SwiftUI and name it `IOSNotify`.
2. Copy the folders in this repository into the generated Xcode project (or add the files individually).
3. Enable the *Background Modes* and *Push Notifications* capabilities if you plan to test local notification delivery while the app is backgrounded.
4. Run on a simulator or device. The sample data from `Schedule.bootstrapSamples()` will pre-populate two schedules for exploration.

### Next Steps

- Wire up custom notification sounds (drop `.caf` files into `Resources/` and update `ScheduleItem.soundIdentifier` values).
- Harden persistence (e.g., migrate to SwiftData or Core Data).
- Expand validation and UX polish in the editor (duration pickers, finer-grained controls).
- Add unit/UI tests to verify timer progression, pause/resume correctness, and notification scheduling.
