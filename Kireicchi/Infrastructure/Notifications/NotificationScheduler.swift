import Foundation
import UserNotifications
import UIKit

final class NotificationScheduler: NotificationSchedulerProtocol {
    private let center = UNUserNotificationCenter.current()
    private static let reminderID = "kireicchi.daily-photo-reminder"

    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted {
            // lowScoreWarning（家出予告等）のプッシュ通知を受け取れるよう、
            // 許可と同時にAPNsへのリモート通知登録も行う。
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        }
        return granted
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
