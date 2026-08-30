import Foundation
import SwiftData

@MainActor
struct PostcardStore: PostcardStoreProtocol {
    let context: ModelContext

    func save(_ record: PostcardRecord) throws {
        context.insert(record)
        try context.save()
    }

    func fetchAll() throws -> [PostcardRecord] {
        let descriptor = FetchDescriptor<PostcardRecord>(
            sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func existingIds() throws -> Set<String> {
        Set(try context.fetch(FetchDescriptor<PostcardRecord>()).map(\.id))
    }

    func delete(_ record: PostcardRecord) throws {
        context.delete(record)
        try context.save()
    }
}
