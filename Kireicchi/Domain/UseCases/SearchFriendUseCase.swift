import Foundation

final class SearchFriendUseCase: SearchFriendUseCaseProtocol {
    private let repository: UserIdRepositoryProtocol

    init(repository: UserIdRepositoryProtocol) {
        self.repository = repository
    }

    func execute(userId: String, myUid: String) async throws -> FriendProfile {
        let normalized = UserIdRepository.normalize(userId)
        guard !normalized.isEmpty, let profile = try await repository.lookup(userId: normalized) else {
            throw FriendError.userNotFound
        }
        guard profile.uid != myUid else {
            throw FriendError.cannotAddSelf
        }
        return profile
    }
}
