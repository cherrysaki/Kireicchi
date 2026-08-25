import Foundation

/// ダミーデータを返すお知らせRepository。
/// 3種類（parentMessage / lowScoreWarning / friendRequest）・既読/未読が
/// 混在したデータをメモリ上に保持し、markAsRead でその場で更新する。
final class MockNotificationRepository: NotificationRepositoryProtocol {
    private var notifications: [AppNotification]

    init() {
        let now = Date()
        notifications = [
            AppNotification(
                id: "1",
                kind: .lowScoreWarning,
                title: "きれいっちが弱ってるよ！",
                body: "散らかり度が高い状態が3日続いています。そろそろ片付けてあげよう。",
                createdAt: now.addingTimeInterval(-60 * 30),
                isRead: false
            ),
            AppNotification(
                id: "2",
                kind: .parentMessage,
                title: "保護者からのメッセージ",
                body: "お片付けしようね！応援してるよ😊",
                createdAt: now.addingTimeInterval(-60 * 60 * 3),
                isRead: false
            ),
            AppNotification(
                id: "3",
                kind: .friendRequest,
                title: "フレンド申請が届いています",
                body: "「ゆっけ」さんからフレンド申請が届いています。",
                createdAt: now.addingTimeInterval(-60 * 60 * 5),
                isRead: false
            ),
            AppNotification(
                id: "4",
                kind: .parentMessage,
                title: "保護者からのメッセージ",
                body: "今日もお部屋の様子見せてね！",
                createdAt: now.addingTimeInterval(-60 * 60 * 26),
                isRead: true
            ),
            AppNotification(
                id: "5",
                kind: .lowScoreWarning,
                title: "きれいっちが心配してるよ",
                body: "2日間撮影がありません。お部屋の様子を確認してね。",
                createdAt: now.addingTimeInterval(-60 * 60 * 30),
                isRead: true
            ),
            AppNotification(
                id: "6",
                kind: .friendRequest,
                title: "フレンド申請が届いています",
                body: "「みなみ」さんからフレンド申請が届いています。",
                createdAt: now.addingTimeInterval(-60 * 60 * 48),
                isRead: true
            ),
            AppNotification(
                id: "7",
                kind: .lowScoreWarning,
                title: "きれいっちが死んじゃうかも…！",
                body: "散らかり度が低い状態が5日続いています。今すぐ片付けよう！",
                createdAt: now.addingTimeInterval(-60 * 60 * 72),
                isRead: false
            )
        ]
    }

    func fetchAll() async throws -> [AppNotification] {
        notifications.sorted { $0.createdAt > $1.createdAt }
    }

    func markAsRead(id: String) async throws {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
    }
}
