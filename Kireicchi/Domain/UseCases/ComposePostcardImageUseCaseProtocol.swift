import Foundation

protocol ComposePostcardImageUseCaseProtocol {
    func execute(pixelArtData: Data, characterType: CharacterType, characterState: CharacterState) -> Data
}
