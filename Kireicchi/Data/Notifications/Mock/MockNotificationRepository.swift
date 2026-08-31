import Foundation

/// Preview 用のお知らせ Repository。notifications をそのまま返し、markAsRead でメモリ上を更新する。
final class MockNotificationRepository: NotificationRepositoryProtocol {
    var notifications: [AppNotification]

    init(notifications: [AppNotification] = []) {
        self.notifications = notifications
    }

    func fetchAll(input: NotificationInput) async throws -> [AppNotification] {
        notifications.sorted { $0.createdAt > $1.createdAt }
    }

    func markAsRead(id: String) async throws {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
    }
}
