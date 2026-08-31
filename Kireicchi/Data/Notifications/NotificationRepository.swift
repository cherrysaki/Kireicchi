import Foundation
import FirebaseFirestore

/// AppNotification のうち .lowScoreWarning のみ、Firestore の実データ
/// （users/{uid}/appNotifications。Cloud Functions の dailyCrisisNotifications が
/// 危機レベル「注意」「家出」の間、毎日1件ずつ書き込む）に接続する。
///
/// .parentMessage / .friendRequest はまだ実データソースが無いため、ダミーデータの
/// まま返す。将来の差し替え方針:
/// - parentMessage: LINE Quick Reply連携の実装後、専用Repositoryに差し替え
/// - friendRequest: フレンド機能の実装後、専用Repositoryに差し替え
final class NotificationRepository: NotificationRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
    }

    func fetchAll() async throws -> [AppNotification] {
        guard let uid = authService.currentUid else {
            return Self.dummyNotifications
        }

        let snapshot = try await db.collection("users").document(uid)
            .collection("appNotifications")
            .order(by: "createdAt", descending: true)
            .getDocuments()

        let lowScoreWarnings: [AppNotification] = snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let title = data["title"] as? String,
                  let body = data["body"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else { return nil }
            return AppNotification(
                id: doc.documentID,
                kind: .lowScoreWarning,
                title: title,
                body: body,
                createdAt: timestamp.dateValue(),
                isRead: data["isRead"] as? Bool ?? false
            )
        }

        return (lowScoreWarnings + Self.dummyNotifications)
            .sorted { $0.createdAt > $1.createdAt }
    }

    func markAsRead(id: String) async throws {
        guard let uid = authService.currentUid else { return }
        // .parentMessage/.friendRequest はダミーIDのためFirestoreに存在せず、
        // 更新は失敗するが無視してよい（実データ接続後は自然に解消する）。
        try? await db.collection("users").document(uid)
            .collection("appNotifications").document(id)
            .updateData(["isRead": true])
    }

    private static let dummyNotifications: [AppNotification] = [
        AppNotification(
            id: "dummy-parent-1",
            kind: .parentMessage,
            title: "保護者からのメッセージ",
            body: "お片付けしようね！応援してるよ😊",
            createdAt: Date().addingTimeInterval(-60 * 60 * 3),
            isRead: false
        ),
        AppNotification(
            id: "dummy-friend-1",
            kind: .friendRequest,
            title: "フレンド申請が届いています",
            body: "「ゆっけ」さんからフレンド申請が届いています。",
            createdAt: Date().addingTimeInterval(-60 * 60 * 5),
            isRead: false
        ),
    ]
}
