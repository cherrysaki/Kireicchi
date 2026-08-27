import Foundation

/// 部屋のスコアを Firestore の users/{uid}/roomScores サブコレクションへ書き込む。
protocol RoomScoreRepositoryProtocol: Sendable {
    func save(uid: String, score: Int, rank: String) async throws
}
