import Foundation

protocol FetchNotificationsUseCaseProtocol {
    func execute(input: NotificationInput) async throws -> [AppNotification]
}
