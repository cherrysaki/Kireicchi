import Foundation

final class GeneratePixelArtUseCase: GeneratePixelArtUseCaseProtocol {
    private let openAIClient: OpenAIClientProtocol

    init(openAIClient: OpenAIClientProtocol) {
        self.openAIClient = openAIClient
    }

    func execute(imageData: Data) async throws -> Data {
        return try await openAIClient.generatePixelArt(imageData: imageData)
    }
}
