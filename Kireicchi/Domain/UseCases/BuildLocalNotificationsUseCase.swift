import Foundation

final class BuildLocalNotificationsUseCase: BuildLocalNotificationsUseCaseProtocol {
    private static let lowScoreThreshold = 39
    private static let noCaptureDays = 2

    private let calendar = Calendar.current

    func execute(input: NotificationInput) -> [AppNotification] {
        var result: [AppNotification] = []
        let dayKey = Self.dayKey(for: input.now)
        let capturedToday = input.latestCapturedAt.map { calendar.isDate($0, inSameDayAs: input.now) } ?? false

        if input.reminder.isEnabled, !capturedToday,
           let reminderTime = calendar.date(
               bySettingHour: input.reminder.hour, minute: input.reminder.minute, second: 0, of: input.now
           ),
           reminderTime <= input.now {
            result.append(AppNotification(
                id: "captureReminder:\(dayKey)",
                kind: .captureReminder,
                title: "撮影の時間です",
                body: "お部屋の撮影時間だよ！📸",
                createdAt: reminderTime,
                isRead: false
            ))
        }

        if let score = input.latestScore, let capturedAt = input.latestCapturedAt {
            if score <= Self.lowScoreThreshold {
                result.append(AppNotification(
                    id: "lowScore:\(Self.dayKey(for: capturedAt))",
                    kind: .lowScoreWarning,
                    title: "きれいっちが弱ってるよ！",
                    body: "お部屋の散らかり度が高いみたい。そろそろ片付けてあげよう。",
                    createdAt: capturedAt,
                    isRead: false
                ))
            }

            let daysSince = calendar.dateComponents(
                [.day], from: calendar.startOfDay(for: capturedAt), to: calendar.startOfDay(for: input.now)
            ).day ?? 0
            if daysSince >= Self.noCaptureDays {
                result.append(AppNotification(
                    id: "noCapture:\(dayKey)",
                    kind: .lowScoreWarning,
                    title: "きれいっちが心配してるよ",
                    body: "\(daysSince)日間撮影がありません。お部屋の様子を確認してね。",
                    createdAt: calendar.startOfDay(for: input.now),
                    isRead: false
                ))
            }
        }

        return result
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
