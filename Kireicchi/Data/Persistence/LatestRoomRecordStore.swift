import Foundation
import SwiftData

@MainActor
struct LatestRoomRecordStore {
    let context: ModelContext

    func save(pixelArtImageData: Data,
              originalImageData: Data?,
              capturedAt: Date,
              score: Int,
              comment: String,
              missions: [MissionPersisted],
              messyPointLabels: [String]?) throws {
        let missionsData = try? JSONEncoder().encode(missions)
        let existing = try context.fetch(FetchDescriptor<LatestRoomRecord>())
        if let first = existing.first {
            first.pixelArtImageData = pixelArtImageData
            first.originalImageData = originalImageData
            first.capturedAt = capturedAt
            first.score = score
            first.comment = comment
            first.messyPointLabels = messyPointLabels
            first.missionsData = missionsData
            for extra in existing.dropFirst() {
                context.delete(extra)
            }
        } else {
            context.insert(LatestRoomRecord(
                pixelArtImageData: pixelArtImageData,
                capturedAt: capturedAt,
                score: score,
                comment: comment,
                messyPointLabels: messyPointLabels,
                originalImageData: originalImageData,
                missionsData: missionsData
            ))
        }
        try context.save()
    }

    func updateMission(id: String, isDone: Bool) throws {
        let existing = try context.fetch(FetchDescriptor<LatestRoomRecord>())
        guard let record = existing.first else { return }
        var current = record.missions
        guard let idx = current.firstIndex(where: { $0.id == id }) else { return }
        current[idx].isDone = isDone
        record.missions = current
        try context.save()
    }
}
