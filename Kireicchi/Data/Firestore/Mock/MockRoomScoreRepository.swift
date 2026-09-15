import Foundation

final class MockRoomScoreRepository: RoomScoreRepositoryProtocol {
    func save(uid: String, score: Int, rank: String, pixelArtImageData: Data?) async throws {}
}
