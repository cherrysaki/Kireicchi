import Foundation

@MainActor
struct MockRoomHistoryStore: RoomHistoryStoreProtocol {
    func save(_ record: RoomHistoryRecord) throws {}

    func fetchAll() throws -> [RoomHistoryRecord] {
        let calendar = Calendar.current
        let scores = [82, 65, 48, 73, 90, 55, 38, 68, 77, 30]
        return scores.enumerated().compactMap { offset, score in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let rank = CleanlinessRank.fromScore(score).rawValue
            return RoomHistoryRecord(capturedAt: date, score: score, rank: rank)
        }
    }
}
