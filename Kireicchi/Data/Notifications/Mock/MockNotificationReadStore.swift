import Foundation

final class MockNotificationReadStore: NotificationReadStoreProtocol {
    var ids: Set<String> = []

    func readIds() -> Set<String> { ids }

    func markAsRead(id: String) {
        ids.insert(id)
    }
}
