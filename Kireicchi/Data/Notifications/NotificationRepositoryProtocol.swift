import Foundation

/// お知らせ（保護者からの連絡・スコア低下の危機通知・フレンド申請）の
/// 取得・既読管理を担う。
///
/// 実データ接続方針（将来差し替え予定、今回は未実装）:
/// - 保護者からの「お片づけしようね」: LINE公式アカウントにQuick Replyボタンを
///   用意し、押されたらFirestore経由でアプリに配信する実装に差し替える想定
/// - 危機通知: roomScoresの低スコア継続日数を判定するロジックと連動する
///   実装に差し替える想定
/// - フレンド申請: 別メンバーが実装するフレンド機能のデータソースへ接続する
///   実装に差し替える想定（インターフェースは実装後に調整が必要になる可能性あり）
///
/// いずれも本Protocolに準拠した実装（例: NotificationRepository）へ差し替える
/// だけでUseCase/View側の変更は不要な設計にしている。
protocol NotificationRepositoryProtocol {
    func fetchAll() async throws -> [AppNotification]
    func markAsRead(id: String) async throws
}
