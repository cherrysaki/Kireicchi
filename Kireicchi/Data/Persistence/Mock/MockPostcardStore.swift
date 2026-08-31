import Foundation

@MainActor
final class MockPostcardStore: PostcardStoreProtocol {
    var records: [PostcardRecord] = []

    func save(_ record: PostcardRecord) throws {
        records.append(record)
    }

    func fetchAll() throws -> [PostcardRecord] {
        records.sorted { $0.sentAt > $1.sentAt }
    }

    func existingIds() throws -> Set<String> {
        Set(records.map(\.id))
    }

    func delete(_ record: PostcardRecord) throws {
        records.removeAll { $0.id == record.id }
    }
}
