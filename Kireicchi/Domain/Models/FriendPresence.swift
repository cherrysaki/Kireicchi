import Foundation

struct FriendPresence: Equatable, Sendable {
    let peerId: String
    let displayName: String
    let characterId: String

    var characterType: CharacterType {
        CharacterType(rawValue: characterId) ?? .character01
    }
}
