import Foundation

/// 既読にしたお知らせ ID を UserDefaults に保持する。
final class NotificationReadStore: NotificationReadStoreProtocol {
    private static let key = "readNotificationIds"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func readIds() -> Set<String> {
        Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func markAsRead(id: String) {
        var ids = readIds()
        guard ids.insert(id).inserted else { return }
        defaults.set(Array(ids), forKey: Self.key)
    }
}
