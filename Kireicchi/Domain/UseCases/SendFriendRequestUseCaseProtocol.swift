import Foundation

protocol SendFriendRequestUseCaseProtocol {
    func execute(from: FriendProfile, to: FriendProfile) async throws
}
