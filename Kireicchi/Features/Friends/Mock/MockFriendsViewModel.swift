import Foundation
import Combine

@MainActor
final class MockFriendsViewModel: FriendsViewModelProtocol {
    @Published var myProfile: FriendProfile? = FriendProfile(uid: "me", username: "さき", selectedCharacterId: "character01", userId: "K7PQ2M9X")
    @Published var friends: [FriendProfile] = [
        FriendProfile(uid: "u1", username: "ぽろこ", selectedCharacterId: "character01"),
        FriendProfile(uid: "u2", username: "みなみ", selectedCharacterId: "character01")
    ]
    @Published var incomingRequests: [FriendRequest] = [
        FriendRequest(id: "u3_me", fromUid: "u3", toUid: "me", fromUsername: "ゆっけ", toUsername: "さき",
                      status: .pending, createdAt: Date(), updatedAt: Date())
    ]
    @Published var outgoingRequests: [FriendRequest] = [
        FriendRequest(id: "me_u4", fromUid: "me", toUid: "u4", fromUsername: "さき", toUsername: "たろう",
                      status: .pending, createdAt: Date(), updatedAt: Date())
    ]
    @Published var searchText: String = ""
    @Published var searchResult: FriendProfile? = nil
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String? = nil
    @Published var infoMessage: String? = nil

    func load() async {}
    func search() async {
        searchResult = FriendProfile(uid: "u5", username: searchText, selectedCharacterId: "character01")
    }
    func sendRequest(to profile: FriendProfile) async {}
    func accept(_ request: FriendRequest) async {}
    func decline(_ request: FriendRequest) async {}
    func cancel(_ request: FriendRequest) async {}
    func removeFriend(_ friend: FriendProfile) async {}
    func relation(with profile: FriendProfile) -> FriendRelation { .none }
}
