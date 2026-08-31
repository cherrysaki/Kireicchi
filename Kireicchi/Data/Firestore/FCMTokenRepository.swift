import Foundation
import FirebaseFirestore

/// users/{uid}.fcmToken にトークンを書き込む。
/// dailyCrisisNotifications（Cloud Functions）がこのフィールドを読み、
/// lowScoreWarning（家出予告等）のプッシュ通知先として利用する。
final class FCMTokenRepository: FCMTokenRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }

    func save(uid: String, token: String) async throws {
        try await db.collection("users").document(uid).setData(
            [
                "fcmToken": token,
                "fcmTokenUpdatedAt": FieldValue.serverTimestamp()
            ],
            merge: true
        )
    }
}
