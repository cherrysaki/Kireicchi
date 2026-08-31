import Foundation

final class MockUserIdRepository: UserIdRepositoryProtocol {
    var profiles: [String: FriendProfile] = [:]

    func generateAndReserve(uid: String) async throws -> String {
        let id = "MOCK\(uid.prefix(4).uppercased())"
        profiles[id] = FriendProfile(uid: uid, username: "mock", selectedCharacterId: "character01", userId: id)
        return id
    }

    func change(to newUserId: String, uid: String, previousUserId: String?) async throws {
        let id = newUserId.uppercased()
        if let existing = profiles[id], existing.uid != uid { throw FriendError.userIdTaken }
        if let previous = previousUserId { profiles.removeValue(forKey: previous) }
        profiles[id] = FriendProfile(uid: uid, username: "mock", selectedCharacterId: "character01", userId: id)
    }

    func lookup(userId: String) async throws -> FriendProfile? {
        profiles[userId.uppercased()]
    }
}
