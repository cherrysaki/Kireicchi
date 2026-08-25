import Foundation

/// お知らせの種別。
///
/// 実データ接続方針（将来差し替え予定、今回は未実装）:
/// - parentMessage: LINE公式アカウントのQuick Reply経由でFirestoreに配信された
///   保護者からのメッセージを想定
/// - lowScoreWarning: roomScoresの低スコア継続日数を判定するロジックと連動する
///   想定
/// - friendRequest: 別メンバーが実装するフレンド機能のデータソースへ接続する
///   想定（インターフェースは実装後に調整の可能性あり）
enum AppNotificationKind {
    case parentMessage
    case lowScoreWarning
    case friendRequest
}

struct AppNotification: Identifiable, Equatable {
    let id: String
    let kind: AppNotificationKind
    let title: String
    let body: String
    let createdAt: Date
    var isRead: Bool
}
