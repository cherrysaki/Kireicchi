import Foundation

enum CharacterMood: String, CaseIterable, Codable, Hashable, Sendable {
    case happy = "元気"
    case normal = "普通"
    case sad = "不調"
    case sick = "病気"

    static func fromScore(_ score: Int) -> CharacterMood {
        switch score {
        case 80...100: return .happy
        case 60...79:  return .normal
        case 40...59:  return .sad
        default:       return .sick
        }
    }

    static func fromHappiness(_ happiness: Int) -> CharacterMood {
        switch happiness {
        case 75...100: return .happy
        case 50...74:  return .normal
        case 25...49:  return .sad
        default:       return .sick
        }
    }

    var assetSuffix: String {
        switch self {
        case .happy:  return "happy"
        case .normal: return "normal"
        case .sad:    return "sad"
        case .sick:   return "sick"
        }
    }
}
