import Foundation

enum CharacterType: String, CaseIterable {
    case character01 = "character01"
    
    func gifName(for state: CharacterState) -> String {
        return "\(self.rawValue)_\(state.gifSuffix)"
    }
    
    var walkGifName: String {
        return "\(self.rawValue)_walk"
    }
    
    var cheerGifName: String {
        return "\(self.rawValue)_cheer"
    }
}