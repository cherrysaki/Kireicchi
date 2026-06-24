import Foundation

protocol RoomHistoryStoreProtocol {
    func save(_ record: RoomHistoryRecord) throws
    func fetchAll() throws -> [RoomHistoryRecord]
}
