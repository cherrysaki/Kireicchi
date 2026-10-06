import Foundation

struct CharacterPresentation: Hashable, Sendable {
    let characterType: CharacterType
    let formID: CharacterFormID
    let mood: CharacterMood
    let action: CharacterAction
}
