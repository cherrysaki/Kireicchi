import Foundation

protocol GeneratePixelArtUseCaseProtocol {
    func execute(imageData: Data) async throws -> Data
}
