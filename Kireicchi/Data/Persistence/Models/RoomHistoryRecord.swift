import Foundation
import SwiftData

@Model
final class RoomHistoryRecord {
    var id: UUID
    var capturedAt: Date
    var score: Int
    var rank: String
    var pixelArtImageData: Data?

    init(capturedAt: Date, score: Int, rank: String, pixelArtImageData: Data? = nil) {
        self.id = UUID()
        self.capturedAt = capturedAt
        self.score = score
        self.rank = rank
        self.pixelArtImageData = pixelArtImageData
    }
}
