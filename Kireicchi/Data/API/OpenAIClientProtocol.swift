import Foundation

protocol OpenAIClientProtocol {
    func analyzeRoom(imageData: Data) async throws -> RoomAnalysisResponse
}