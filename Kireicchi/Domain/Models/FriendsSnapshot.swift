import Foundation

struct FriendsSnapshot: Equatable {
    var friends: [FriendProfile]
    var incomingRequests: [FriendRequest]
    var outgoingRequests: [FriendRequest]

    static let empty = FriendsSnapshot(friends: [], incomingRequests: [], outgoingRequests: [])
}
