import Foundation
import FirebaseFirestore

/// friendRequests/{from}_{to} と friendships/{a}_{b} を扱う。
/// 承認時は request 更新と friendship 作成を 1 バッチで行い、セキュリティルール側で
/// getAfter による整合性チェックを受ける。
final class FriendRepository: FriendRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }

    private var requests: CollectionReference { db.collection("friendRequests") }
    private var friendships: CollectionReference { db.collection("friendships") }

    func fetchFriends(uid: String) async throws -> [FriendProfile] {
        let snapshot = try await friendships
            .whereField("members", arrayContains: uid)
            .getDocuments()
        let friendUids = snapshot.documents
            .compactMap { try? $0.data(as: Friendship.self) }
            .compactMap { $0.otherMember(than: uid) }

        var profiles: [FriendProfile] = []
        for friendUid in friendUids {
            if let profile = try await fetchProfile(uid: friendUid) {
                profiles.append(profile)
            }
        }
        return profiles.sorted { $0.username < $1.username }
    }

    func fetchIncomingRequests(uid: String) async throws -> [FriendRequest] {
        try await fetchPendingRequests(field: "toUid", uid: uid)
    }

    func fetchOutgoingRequests(uid: String) async throws -> [FriendRequest] {
        try await fetchPendingRequests(field: "fromUid", uid: uid)
    }

    func sendRequest(from: FriendProfile, to: FriendProfile) async throws {
        if try await friendships.document(Friendship.documentId(from.uid, to.uid)).getDocument().exists {
            throw FriendError.alreadyFriends
        }
        let reverse = try await requests.document(FriendRequest.documentId(from: to.uid, to: from.uid)).getDocument()
        if reverse.exists, (reverse.data()?["status"] as? String) == FriendRequestStatus.pending.rawValue {
            throw FriendError.requestAlreadyReceived
        }
        let forwardRef = requests.document(FriendRequest.documentId(from: from.uid, to: to.uid))
        let forward = try await forwardRef.getDocument()
        if forward.exists, (forward.data()?["status"] as? String) == FriendRequestStatus.pending.rawValue {
            throw FriendError.requestAlreadySent
        }

        let now = Date()
        let request = FriendRequest(
            fromUid: from.uid,
            toUid: to.uid,
            fromUsername: from.username,
            toUsername: to.username,
            status: .pending,
            createdAt: now,
            updatedAt: now
        )
        try forwardRef.setData(from: request)
    }

    func acceptRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else { return }
        let batch = db.batch()
        batch.updateData([
            "status": FriendRequestStatus.accepted.rawValue,
            "updatedAt": Timestamp(date: Date())
        ], forDocument: requests.document(requestId))

        let friendship = Friendship(
            members: Friendship.sortedMembers(request.fromUid, request.toUid),
            createdAt: Date()
        )
        try batch.setData(from: friendship, forDocument: friendships.document(Friendship.documentId(request.fromUid, request.toUid)))
        try await batch.commit()
    }

    func declineRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else { return }
        try await requests.document(requestId).delete()
    }

    func cancelRequest(_ request: FriendRequest) async throws {
        guard let requestId = request.id else { return }
        try await requests.document(requestId).delete()
    }

    func removeFriend(uid: String, friendUid: String) async throws {
        let batch = db.batch()
        batch.deleteDocument(friendships.document(Friendship.documentId(uid, friendUid)))
        batch.deleteDocument(requests.document(FriendRequest.documentId(from: uid, to: friendUid)))
        batch.deleteDocument(requests.document(FriendRequest.documentId(from: friendUid, to: uid)))
        try await batch.commit()
    }

    private func fetchPendingRequests(field: String, uid: String) async throws -> [FriendRequest] {
        let snapshot = try await requests
            .whereField(field, isEqualTo: uid)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: FriendRequest.self) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func fetchProfile(uid: String) async throws -> FriendProfile? {
        let snapshot = try await db.collection("users").document(uid).getDocument()
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        let username = (data["username"] as? String) ?? (data["displayName"] as? String) ?? "ともだち"
        let characterId = data["selectedCharacterId"] as? String ?? CharacterType.character01.rawValue
        return FriendProfile(uid: uid, username: username, selectedCharacterId: characterId, userId: data["userId"] as? String)
    }
}
