import Foundation
import FirebaseFirestore

struct AppUser: Codable, Equatable {
    @DocumentID var uid: String?
    var createdAt: Date
    var updatedAt: Date
    var authProvider: String
    var displayName: String?
    var username: String?
    /// ともだち検索用の英数字ID（userIds/{userId} で一意性を担保）
    var userId: String?
    var selectedCharacterId: String
    var notificationSettings: NotificationSettingsData

    static func makeDefault(uid: String, authProvider: String, now: Date = Date()) -> AppUser {
        AppUser(
            uid: uid,
            createdAt: now,
            updatedAt: now,
            authProvider: authProvider,
            displayName: nil,
            username: nil,
            userId: nil,
            selectedCharacterId: "cat",
            notificationSettings: .default
        )
    }
}

struct NotificationSettingsData: Codable, Equatable {
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    static let `default` = NotificationSettingsData(hour: 19, minute: 0, isEnabled: true)
}
