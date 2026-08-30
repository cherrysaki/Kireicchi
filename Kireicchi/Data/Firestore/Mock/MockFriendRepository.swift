import Foundation

final class MockFriendRepository: FriendRepositoryProtocol {
    var friends: [FriendProfile] = []
    var incoming: [FriendRequest] = []
    var outgoing: [FriendRequest] = []

    func fetchFriends(uid: String) async throws -> [FriendProfile] { friends }
    func fetchIncomingRequests(uid: String) async throws -> [FriendRequest] { incoming }
    func fetchOutgoingRequests(uid: String) async throws -> [FriendRequest] { outgoing }

    func sendRequest(from: FriendProfile, to: FriendProfile) async throws {
        let now = Date()
        outgoing.append(FriendRequest(
            id: FriendRequest.documentId(from: from.uid, to: to.uid),
            fromUid: from.uid, toUid: to.uid,
            fromUsername: from.username, toUsername: to.username,
            status: .pending, createdAt: now, updatedAt: now
        ))
    }

    func acceptRequest(_ request: FriendRequest) async throws {
        incoming.removeAll { $0.id == request.id }
        friends.append(FriendProfile(uid: request.fromUid, username: request.fromUsername, selectedCharacterId: CharacterType.character01.rawValue))
    }

    func declineRequest(_ request: FriendRequest) async throws {
        incoming.removeAll { $0.id == request.id }
    }

    func cancelRequest(_ request: FriendRequest) async throws {
        outgoing.removeAll { $0.id == request.id }
    }

    func removeFriend(uid: String, friendUid: String) async throws {
        friends.removeAll { $0.uid == friendUid }
    }
}
