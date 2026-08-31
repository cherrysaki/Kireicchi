import Foundation

protocol UserIdRepositoryProtocol {
    /// 英数字のユーザーIDを生成して userIds/{userId} に予約し、そのIDを返す。衝突したら再生成する。
    func generateAndReserve(uid: String) async throws -> String
    /// ユーザーIDを newUserId に変更する。他人が使用中なら FriendError.userIdTaken。
    func change(to newUserId: String, uid: String, previousUserId: String?) async throws
    func lookup(userId: String) async throws -> FriendProfile?
}
