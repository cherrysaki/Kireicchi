import Foundation

enum CharacterAction: String, CaseIterable, Codable, Hashable, Sendable {
    case idle
    case walk
    case cheer
    case run
}
