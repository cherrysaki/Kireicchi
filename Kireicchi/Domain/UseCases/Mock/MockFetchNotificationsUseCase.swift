import Foundation

final class MockFetchNotificationsUseCase: FetchNotificationsUseCaseProtocol {
    var notifications: [AppNotification] = []

    func execute(input: NotificationInput) async throws -> [AppNotification] {
        notifications
    }
}
