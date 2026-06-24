import Foundation

enum CleanlinessRank: String, CaseIterable, Hashable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    
    static func fromScore(_ score: Int) -> CleanlinessRank {
        switch score {
        case 85...100: return .a
        case 70...84: return .b
        case 50...69: return .c
        case 30...49: return .d
        default: return .e
        }
    }
}