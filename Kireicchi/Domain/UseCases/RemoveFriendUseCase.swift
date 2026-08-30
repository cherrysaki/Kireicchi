import Foundation

final class RemoveFriendUseCase: RemoveFriendUseCaseProtocol {
    private let repository: FriendRepositoryProtocol

    init(repository: FriendRepositoryProtocol) {
        self.repository = repository
    }

    func execute(uid: String, friendUid: String) async throws {
        try await repository.removeFriend(uid: uid, friendUid: friendUid)
    }
}
