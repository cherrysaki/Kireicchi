import Foundation

final class MockFetchNotificationsUseCase: FetchNotificationsUseCaseProtocol {
    var notifications: [AppNotification] = []

    func execute() async throws -> [AppNotification] {
        notifications
    }
}
