import Foundation
import SwiftData

@Model
final class RoomHistoryRecord {
    var id: UUID
    var capturedAt: Date
    var score: Int
    var rank: String
    var pixelArtImageData: Data?
    var comment: String?
    var missionsData: Data?

    init(capturedAt: Date, score: Int, rank: String, pixelArtImageData: Data? = nil,
         comment: String? = nil, missions: [MissionPersisted] = []) {
        self.id = UUID()
        self.capturedAt = capturedAt
        self.score = score
        self.rank = rank
        self.pixelArtImageData = pixelArtImageData
        self.comment = comment
        self.missionsData = missions.isEmpty ? nil : (try? JSONEncoder().encode(missions))
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
