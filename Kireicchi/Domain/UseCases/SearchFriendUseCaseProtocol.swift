import Foundation

protocol SearchFriendUseCaseProtocol {
    func execute(userId: String, myUid: String) async throws -> FriendProfile
}
