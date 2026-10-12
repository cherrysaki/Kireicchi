import Foundation

enum CharacterPlaybackMode: Equatable, Sendable {
    case homeIdle
    case fixed(CharacterAction)
}
