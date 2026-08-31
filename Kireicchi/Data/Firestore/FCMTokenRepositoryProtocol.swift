import Foundation

/// FCMトークンを Firestore の users/{uid} ドキュメントへ保存する。
protocol FCMTokenRepositoryProtocol: Sendable {
    func save(uid: String, token: String) async throws
}
