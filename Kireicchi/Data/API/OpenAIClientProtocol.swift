import Foundation

protocol OpenAIClientProtocol {
    func analyzeRoom(imageData: Data) async throws -> RoomAnalysisResponse
    func generatePixelArt(imageData: Data) async throws -> Data
}