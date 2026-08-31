import Foundation

final class FetchNotificationsUseCase: FetchNotificationsUseCaseProtocol {
    private let repository: NotificationRepositoryProtocol

    init(repository: NotificationRepositoryProtocol) {
        self.repository = repository
    }

    func execute(input: NotificationInput) async throws -> [AppNotification] {
        try await repository.fetchAll(input: input)
    }
}
