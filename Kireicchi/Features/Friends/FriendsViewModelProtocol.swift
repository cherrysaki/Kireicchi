import Foundation
import Combine

@MainActor
protocol FriendsViewModelProtocol: ObservableObject {
    var myProfile: FriendProfile? { get }
    var friends: [FriendProfile] { get }
    var incomingRequests: [FriendRequest] { get }
    var outgoingRequests: [FriendRequest] { get }
    var searchText: String { get set }
    var searchResult: FriendProfile? { get }
    var isLoading: Bool { get }
    var isSearching: Bool { get }
    var errorMessage: String? { get set }
    var infoMessage: String? { get set }

    func load() async
    func search() async
    func sendRequest(to profile: FriendProfile) async
    func accept(_ request: FriendRequest) async
    func decline(_ request: FriendRequest) async
    func cancel(_ request: FriendRequest) async
    func removeFriend(_ friend: FriendProfile) async
    func relation(with profile: FriendProfile) -> FriendRelation
}

enum FriendRelation {
    case none
    case friend
    case requestSent
    case requestReceived
}
