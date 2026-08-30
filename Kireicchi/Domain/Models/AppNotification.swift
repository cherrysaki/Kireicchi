import Foundation

/// お知らせの種別。
///
/// - friendRequest: Firestore friendRequests（自分宛て・pending）
/// - postcardReceived: 受信したポストカード（コレクション保存済み＋未取り込み分）
/// - captureReminder: 設定した撮影時刻を過ぎて今日まだ撮影していないとき
/// - lowScoreWarning: 直近スコアが不調（39以下）または最終撮影から2日以上経過
/// - parentMessage: 保護者からのメッセージ。LINE→アプリの経路が未実装のため現状データ源なし
enum AppNotificationKind {
    case parentMessage
    case lowScoreWarning
    case friendRequest
    case postcardReceived
    case captureReminder
}

struct AppNotification: Identifiable, Equatable {
    let id: String
    let kind: AppNotificationKind
    let title: String
    let body: String
    let createdAt: Date
    var isRead: Bool
}
