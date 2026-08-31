import Foundation
import FirebaseFirestore

struct Friendship: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var members: [String]
    var createdAt: Date

    static func sortedMembers(_ a: String, _ b: String) -> [String] {
        [a, b].sorted()
    }

    static func documentId(_ a: String, _ b: String) -> String {
        sortedMembers(a, b).joined(separator: "_")
    }

    func otherMember(than uid: String) -> String? {
        members.first { $0 != uid }
    }
}
