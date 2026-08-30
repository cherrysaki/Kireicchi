import Foundation

@MainActor
protocol PostcardStoreProtocol {
    func save(_ record: PostcardRecord) throws
    func fetchAll() throws -> [PostcardRecord]
    func existingIds() throws -> Set<String>
    func delete(_ record: PostcardRecord) throws
}
