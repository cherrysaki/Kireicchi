import Foundation
import FirebaseFirestore

/// users/{uid}/roomScores/{scoreId} にスコアを追記する。
/// 接続先はその時点でアクティブな FirebaseApp（既定アプリ）に従うため、
/// 環境（Dev: kireicchiparent-dev / 本番: kireicchi）を意識しない実装になっている。
final class RoomScoreRepository: RoomScoreRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }

    func save(uid: String, score: Int, rank: String) async throws {
        try await db.collection("users").document(uid)
            .collection("roomScores")
            .addDocument(data: [
                "score": score,
                "rank": rank,
                "createdAt": FieldValue.serverTimestamp()
            ])
    }
}
