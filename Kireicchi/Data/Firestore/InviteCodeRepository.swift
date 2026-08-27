import Foundation
import FirebaseFirestore

/// inviteCodes/{code} を作成する。ドキュメントIDにはコード文字列をそのまま使う
/// (LINE側でユーザーが送信したテキストからコードを引くため)。
final class InviteCodeRepository: InviteCodeRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }

    func create(code: String, childId: String, expiresAt: Date) async throws {
        try await db.collection("inviteCodes").document(code).setData([
            "childId": childId,
            "used": false,
            "expiresAt": Timestamp(date: expiresAt)
        ])
    }
}
