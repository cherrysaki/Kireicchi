import Foundation
import SwiftData

@MainActor
struct RoomHistoryStore: RoomHistoryStoreProtocol {
    let context: ModelContext

    func save(_ record: RoomHistoryRecord) throws {
        context.insert(record)
        try context.save()
    }

    func fetchAll() throws -> [RoomHistoryRecord] {
        let descriptor = FetchDescriptor<RoomHistoryRecord>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
