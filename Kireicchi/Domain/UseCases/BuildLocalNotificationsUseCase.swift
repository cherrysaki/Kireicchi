import Foundation

/// 端末内の情報だけから作れるお知らせを生成する。
/// 低スコア・未撮影の警告は Cloud Functions（dailyCrisisNotifications →
/// users/{uid}/appNotifications）側が担うため、ここでは撮影リマインダーのみ扱う。
final class BuildLocalNotificationsUseCase: BuildLocalNotificationsUseCaseProtocol {
    private let calendar = Calendar.current

    func execute(input: NotificationInput) -> [AppNotification] {
        let capturedToday = input.latestCapturedAt.map { calendar.isDate($0, inSameDayAs: input.now) } ?? false
        guard input.reminder.isEnabled, !capturedToday,
              let reminderTime = calendar.date(
                  bySettingHour: input.reminder.hour, minute: input.reminder.minute, second: 0, of: input.now
              ),
              reminderTime <= input.now else {
            return []
        }
        return [AppNotification(
            id: "captureReminder:\(Self.dayKey(for: input.now))",
            kind: .captureReminder,
            title: "撮影の時間です",
            body: "お部屋の撮影時間だよ！📸",
            createdAt: reminderTime,
            isRead: false
        )]
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
