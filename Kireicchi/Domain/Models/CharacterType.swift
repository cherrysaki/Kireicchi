import Foundation

enum CharacterType: String, CaseIterable, Codable, Hashable, Sendable {
    case character01 = "character01"
    case character02 = "character02"
    case character03 = "character03"
    case character04 = "character04"

    var displayName: String {
        switch self {
        case .character01:
            return "きれいっち"
        case .character02:
            return "しずくっち"
        case .character03:
            return "はなっち"
        case .character04:
            return "ほしっち"
        }
    }

    var introduction: String {
        switch self {
        case .character01:
            return "ふわふわ元気なおそうじ仲間"
        case .character02:
            return "水まわりが好きな泡の妖精"
        case .character03:
            return "お花と片づけが好きな妖精"
        case .character04:
            return "お部屋を明るく照らす妖精"
        }
    }
}
