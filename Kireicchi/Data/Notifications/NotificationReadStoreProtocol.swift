import Foundation

protocol NotificationReadStoreProtocol {
    func readIds() -> Set<String>
    func markAsRead(id: String)
}
