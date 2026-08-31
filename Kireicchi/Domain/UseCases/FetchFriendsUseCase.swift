import Foundation

final class FetchFriendsUseCase: FetchFriendsUseCaseProtocol {
    private let repository: FriendRepositoryProtocol

    init(repository: FriendRepositoryProtocol) {
        self.repository = repository
    }

    func execute(uid: String) async throws -> FriendsSnapshot {
        async let friends = repository.fetchFriends(uid: uid)
        async let incoming = repository.fetchIncomingRequests(uid: uid)
        async let outgoing = repository.fetchOutgoingRequests(uid: uid)
        return try await FriendsSnapshot(
            friends: friends,
            incomingRequests: incoming,
            outgoingRequests: outgoing
        )
    }
}
