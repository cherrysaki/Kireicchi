import Foundation
import SwiftData

@Model
final class LatestRoomRecord {
    var pixelArtImageData: Data
    var capturedAt: Date
    var score: Int
    var comment: String

    init(pixelArtImageData: Data, capturedAt: Date, score: Int, comment: String) {
        self.pixelArtImageData = pixelArtImageData
        self.capturedAt = capturedAt
        self.score = score
        self.comment = comment
    }
}
