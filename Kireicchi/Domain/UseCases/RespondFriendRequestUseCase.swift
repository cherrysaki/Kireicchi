import Foundation

final class RespondFriendRequestUseCase: RespondFriendRequestUseCaseProtocol {
    private let repository: FriendRepositoryProtocol

    init(repository: FriendRepositoryProtocol) {
        self.repository = repository
    }

    func accept(_ request: FriendRequest) async throws {
        try await repository.acceptRequest(request)
    }

    func decline(_ request: FriendRequest) async throws {
        try await repository.declineRequest(request)
    }
}
