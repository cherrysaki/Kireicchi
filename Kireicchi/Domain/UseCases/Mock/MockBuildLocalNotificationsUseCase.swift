import Foundation

final class MockBuildLocalNotificationsUseCase: BuildLocalNotificationsUseCaseProtocol {
    var notifications: [AppNotification] = []

    func execute(input: NotificationInput) -> [AppNotification] {
        notifications
    }
}
