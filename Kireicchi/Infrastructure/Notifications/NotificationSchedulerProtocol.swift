import Foundation

protocol NotificationSchedulerProtocol {
    func requestAuthorization() async -> Bool
    func scheduleDailyReminder(hour: Int, minute: Int) async throws
    func cancelAllReminders()
}
