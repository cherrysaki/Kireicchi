import Foundation

/// お知らせの取得・既読管理を担う。
///
/// データ源:
/// - 友達申請: Firestore friendRequests
/// - ポストカード受信: 端末のコレクション（NotificationInput.receivedPostcards）＋ Firestore postcards の未取り込み分
/// - 撮影リマインダー / 低スコア警告: 端末内情報（BuildLocalNotificationsUseCase）
/// 既読状態は派生データのため端末（NotificationReadStore）に ID 集合として保持する。
protocol NotificationRepositoryProtocol {
    func fetchAll(input: NotificationInput) async throws -> [AppNotification]
    func markAsRead(id: String) async throws
}
