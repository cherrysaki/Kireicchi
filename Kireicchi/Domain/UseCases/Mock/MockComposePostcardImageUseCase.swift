import Foundation

final class MockComposePostcardImageUseCase: ComposePostcardImageUseCaseProtocol {
    func execute(pixelArtData: Data, characterType: CharacterType, characterState: CharacterState) -> Data {
        pixelArtData
    }
}
