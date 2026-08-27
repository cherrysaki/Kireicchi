import Foundation

final class MarkNotificationAsReadUseCase: MarkNotificationAsReadUseCaseProtocol {
    private let repository: NotificationRepositoryProtocol

    init(repository: NotificationRepositoryProtocol) {
        self.repository = repository
    }

    func execute(id: String) async throws {
        try await repository.markAsRead(id: id)
    }
}
