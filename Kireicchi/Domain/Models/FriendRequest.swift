import Foundation
import FirebaseFirestore

struct FriendRequest: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var fromUid: String
    var toUid: String
    var fromUsername: String
    var toUsername: String
    var status: FriendRequestStatus
    var createdAt: Date
    var updatedAt: Date

    static func documentId(from: String, to: String) -> String {
        "\(from)_\(to)"
    }
}
