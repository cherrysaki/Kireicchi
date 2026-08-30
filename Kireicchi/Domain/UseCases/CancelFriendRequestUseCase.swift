import Foundation

final class CancelFriendRequestUseCase: CancelFriendRequestUseCaseProtocol {
    private let repository: FriendRepositoryProtocol

    init(repository: FriendRepositoryProtocol) {
        self.repository = repository
    }

    func execute(_ request: FriendRequest) async throws {
        try await repository.cancelRequest(request)
    }
}
