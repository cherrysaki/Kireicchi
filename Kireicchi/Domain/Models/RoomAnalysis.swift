import Foundation

struct RoomAnalysis: Hashable {
    let score: Int
    let rank: CleanlinessRank
    let messyPoints: [String]
    let characterComment: String
    
    var characterState: CharacterState {
        return CharacterState.fromScore(score)
    }
}