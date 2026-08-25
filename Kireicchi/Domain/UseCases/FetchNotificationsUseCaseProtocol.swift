import Foundation

protocol FetchNotificationsUseCaseProtocol {
    func execute() async throws -> [AppNotification]
}
