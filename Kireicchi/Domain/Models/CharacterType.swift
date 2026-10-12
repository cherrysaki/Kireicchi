import Foundation

enum CharacterType: String, CaseIterable, Codable, Hashable, Sendable {
    case character01 = "character01"
    case character02 = "character02"
    case character03 = "character03"
    case character04 = "character04"
    case character05 = "character05"

    var displayName: String {
        switch self {
        case .character01:
            return "きれいっち"
        case .character02:
            return "もっぷっち"
        case .character03:
            return "ほうきっち"
        case .character04:
            return "あわっち"
        case .character05:
            return "ぽっけっち"
        }
    }

    var introduction: String {
        switch self {
        case .character01:
            return "ふわふわ元気なおそうじ仲間"
        case .character02:
            return "ふわふわのお耳で床をぴかぴかに"
        case .character03:
            return "ほうきのしっぽでささっとおそうじ"
        case .character04:
            return "泡のかんむりで水まわりをきれいに"
        case .character05:
            return "小さなポッケでお片づけのお手伝い"
        }
    }
}
