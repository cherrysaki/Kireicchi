import Foundation

final class SendFriendRequestUseCase: SendFriendRequestUseCaseProtocol {
    private let repository: FriendRepositoryProtocol

    init(repository: FriendRepositoryProtocol) {
        self.repository = repository
    }

    func execute(from: FriendProfile, to: FriendProfile) async throws {
        guard from.uid != to.uid else { throw FriendError.cannotAddSelf }
        try await repository.sendRequest(from: from, to: to)
    }
}
