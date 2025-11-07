import Foundation
import UserNotifications

/// Handles local notification scheduling for upcoming schedule items.
final class NotificationManager {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var hasRequestedAuthorization = false

    func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuthorization else { return }
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            if granted {
                self?.hasRequestedAuthorization = true
            }
        }
    }

    func scheduleNotifications(for schedule: Schedule, startingAt startDate: Date) {
        cancelPendingNotifications()

        var cumulativeSeconds = 0
        for item in schedule.items {
            let triggerTime = startDate.addingTimeInterval(TimeInterval(cumulativeSeconds))
            let content = UNMutableNotificationContent()
            content.title = schedule.name
            content.body = item.label
            if let soundIdentifier = item.soundIdentifier {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(soundIdentifier).caf"))
            } else {
                content.sound = UNNotificationSound.default
            }

            let triggerInterval = triggerTime.timeIntervalSinceNow
            guard triggerInterval > 0 else {
                cumulativeSeconds += item.clampedDuration
                continue
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerInterval, repeats: false)

            let request = UNNotificationRequest(
                identifier: makeNotificationIdentifier(scheduleID: schedule.id, itemID: item.id),
                content: content,
                trigger: trigger
            )
            notificationCenter.add(request, withCompletionHandler: nil)
            cumulativeSeconds += item.clampedDuration
        }
    }

    func cancelPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    private func makeNotificationIdentifier(scheduleID: UUID, itemID: UUID) -> String {
        "schedule.\(scheduleID.uuidString).item.\(itemID.uuidString)"
    }
}
