import Foundation

protocol FriendRepositoryProtocol {
    func fetchFriends(uid: String) async throws -> [FriendProfile]
    func fetchIncomingRequests(uid: String) async throws -> [FriendRequest]
    func fetchOutgoingRequests(uid: String) async throws -> [FriendRequest]
    func sendRequest(from: FriendProfile, to: FriendProfile) async throws
    func acceptRequest(_ request: FriendRequest) async throws
    func declineRequest(_ request: FriendRequest) async throws
    func cancelRequest(_ request: FriendRequest) async throws
    func removeFriend(uid: String, friendUid: String) async throws
}
