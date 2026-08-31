import Foundation

protocol RespondFriendRequestUseCaseProtocol {
    func accept(_ request: FriendRequest) async throws
    func decline(_ request: FriendRequest) async throws
}
