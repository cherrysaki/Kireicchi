import Foundation
import SwiftData

@Model
final class LatestRoomRecord {
    var pixelArtImageData: Data
    var capturedAt: Date
    var score: Int
    var comment: String
    var messyPointLabels: [String]? // レガシー: "label:priority" 文字列
    var originalImageData: Data?
    var missionsData: Data?

    init(pixelArtImageData: Data, capturedAt: Date, score: Int,
         comment: String, messyPointLabels: [String]? = nil,
         originalImageData: Data? = nil, missionsData: Data? = nil) {
        self.pixelArtImageData = pixelArtImageData
        self.capturedAt = capturedAt
        self.score = score
        self.comment = comment
        self.messyPointLabels = messyPointLabels
        self.originalImageData = originalImageData
        self.missionsData = missionsData
    }

    @Transient
    var missions: [MissionPersisted] {
        get {
            guard let missionsData else { return [] }
            return (try? JSONDecoder().decode([MissionPersisted].self, from: missionsData)) ?? []
        }
        set {
            missionsData = try? JSONEncoder().encode(newValue)
        }
    }
}
