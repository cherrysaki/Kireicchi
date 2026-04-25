import Foundation
import UserNotifications

final class NotificationScheduler: NotificationSchedulerProtocol {
    private let center = UNUserNotificationCenter.current()
    private static let reminderID = "kireicchi.daily-photo-reminder"

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async throws {
        cancelAllReminders()

        let content = UNMutableNotificationContent()
        content.title = "きれいっち"
        content.body = "お部屋の撮影時間だよ！📸"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: Self.reminderID,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func cancelAllReminders() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
    }
}
