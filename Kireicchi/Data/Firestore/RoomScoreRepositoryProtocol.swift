import Foundation

/// 部屋のスコアを Firestore の users/{uid}/roomScores サブコレクションへ書き込む。
/// pixelArtImageData を渡すと Firebase Storage にも保存し、そのパスを同じ
/// ドキュメントの imagePath フィールドに記録する（LINEダイジェストでの画像送信に使用）。
/// アップロードに失敗しても Firestore への保存自体は失敗させない（imagePath は省略される）。
protocol RoomScoreRepositoryProtocol: Sendable {
    func save(uid: String, score: Int, rank: String, pixelArtImageData: Data?) async throws
}
