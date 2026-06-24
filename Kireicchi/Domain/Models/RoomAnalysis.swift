import Foundation

struct RoomAnalysis: Hashable {
    let score: Int
    let rank: CleanlinessRank
    let messyPoints: [MessyPoint]
    let characterComment: String
    
    var characterState: CharacterState {
        return CharacterState.fromScore(score)
    }
}