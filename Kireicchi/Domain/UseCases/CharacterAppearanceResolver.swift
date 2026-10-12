import Foundation

struct CharacterAppearanceResolver {
    func resolve(
        characterType: CharacterType,
        formID: CharacterFormID = .base,
        mood: CharacterMood,
        action: CharacterAction
    ) -> CharacterPresentation {
        CharacterPresentation(
            characterType: characterType,
            formID: formID,
            mood: mood,
            action: action
        )
    }
}
