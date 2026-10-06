import Foundation

struct CharacterFormID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    static let base = CharacterFormID(rawValue: "base")
}
