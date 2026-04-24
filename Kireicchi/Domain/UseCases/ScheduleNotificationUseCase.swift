import Foundation

final class ScheduleNotificationUseCase: ScheduleNotificationUseCaseProtocol {
    private let scheduler: NotificationSchedulerProtocol

    init(scheduler: NotificationSchedulerProtocol = NotificationScheduler()) {
        self.scheduler = scheduler
    }

    @discardableResult
    func execute(isEnabled: Bool, hour: Int, minute: Int) async -> Bool {
        guard isEnabled else {
            scheduler.cancelAllReminders()
            return true
        }

        let granted = await scheduler.requestAuthorization()
        guard granted else { return false }

        do {
            try await scheduler.scheduleDailyReminder(hour: hour, minute: minute)
            return true
        } catch {
            return false
        }
    }
}
