import Foundation

@MainActor
protocol SyncPostcardsUseCaseProtocol {
    /// Firestore の未取り込みポストカードを端末のコレクションへ保存し、取り込み済みのドキュメントを削除する。
    /// 戻り値は新しく保存した件数。
    func execute(uid: String, store: PostcardStoreProtocol) async throws -> Int
}
