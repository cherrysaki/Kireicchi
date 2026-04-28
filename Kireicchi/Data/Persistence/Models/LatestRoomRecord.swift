import Foundation
import SwiftData

@Model
final class LatestRoomRecord {
    var pixelArtImageData: Data
    var capturedAt: Date
    var score: Int
    var comment: String
    var messyPointLabels: [String]? // オプショナルに変更してマイグレーション対応

    init(pixelArtImageData: Data, capturedAt: Date, score: Int, 
         comment: String, messyPointLabels: [String]? = nil) {
        self.pixelArtImageData = pixelArtImageData
        self.capturedAt = capturedAt
        self.score = score
        self.comment = comment
        self.messyPointLabels = messyPointLabels
    }
}
