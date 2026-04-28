import Foundation
import SwiftData

@MainActor
struct LatestRoomRecordStore {
    let context: ModelContext

    func save(pixelArtImageData: Data, capturedAt: Date, score: Int, 
              comment: String, messyPointLabels: [String]?) throws {
        let existing = try context.fetch(FetchDescriptor<LatestRoomRecord>())
        if let first = existing.first {
            first.pixelArtImageData = pixelArtImageData
            first.capturedAt = capturedAt
            first.score = score
            first.comment = comment
            first.messyPointLabels = messyPointLabels
            for extra in existing.dropFirst() {
                context.delete(extra)
            }
        } else {
            context.insert(LatestRoomRecord(
                pixelArtImageData: pixelArtImageData,
                capturedAt: capturedAt,
                score: score,
                comment: comment,
                messyPointLabels: messyPointLabels
            ))
        }
        try context.save()
    }
}
