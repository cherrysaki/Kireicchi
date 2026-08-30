import Foundation

/// 端末内の情報だけから作れるお知らせ（撮影リマインダー・低スコア・撮影なし）を生成する。
protocol BuildLocalNotificationsUseCaseProtocol {
    func execute(input: NotificationInput) -> [AppNotification]
}
