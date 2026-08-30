import Foundation
import Combine

@MainActor
final class MockSendPostcardViewModel: SendPostcardViewModelProtocol {
    let postcardImageData = Data()
    @Published var includeCharacter = true
    let score = 72
    let rank = "B"
    var myProfile: FriendProfile? = FriendProfile(uid: "me", username: "さき", selectedCharacterId: "character01", userId: "K7PQ2M9X")
    @Published var friends: [FriendProfile] = [
        FriendProfile(uid: "u1", username: "ぽろこ", selectedCharacterId: "character01"),
        FriendProfile(uid: "u2", username: "みなみ", selectedCharacterId: "character01")
    ]
    @Published var selectedUids: Set<String> = ["u1"]
    @Published var isLoading = false
    @Published var isSending = false
    @Published var didSend = false
    @Published var errorMessage: String?

    func load() async {}
    func toggle(_ friend: FriendProfile) {
        if selectedUids.contains(friend.uid) { selectedUids.remove(friend.uid) } else { selectedUids.insert(friend.uid) }
    }
    func send() async { didSend = true }
}
