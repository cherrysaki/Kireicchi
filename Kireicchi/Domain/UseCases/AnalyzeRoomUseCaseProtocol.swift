import Foundation

protocol AnalyzeRoomUseCaseProtocol {
    func execute(imageData: Data) async throws -> RoomAnalysis
}