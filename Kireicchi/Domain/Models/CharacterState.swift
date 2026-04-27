import Foundation

enum CharacterState: String, CaseIterable {
    case happy = "元気"
    case normal = "普通"
    case sad = "不調"
    
    static func fromScore(_ score: Int) -> CharacterState {
        switch score {
        case 70...100:
            return .happy
        case 40...69:
            return .normal
        default:
            return .sad
        }
    }
    
    var gifSuffix: String {
        switch self {
        case .happy: return "happy"
        case .normal: return "sad"
        case .sad: return "sick"
        }
    }
}