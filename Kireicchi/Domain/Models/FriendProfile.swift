import Foundation

struct FriendProfile: Identifiable, Equatable {
    let uid: String
    let username: String
    let selectedCharacterId: String
    var userId: String? = nil

    var id: String { uid }

    var characterType: CharacterType {
        CharacterType(rawValue: selectedCharacterId) ?? .character01
    }
}
