import Foundation

protocol CancelFriendRequestUseCaseProtocol {
    func execute(_ request: FriendRequest) async throws
}
