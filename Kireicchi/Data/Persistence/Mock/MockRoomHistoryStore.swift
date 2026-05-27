import Foundation

@MainActor
struct MockRoomHistoryStore: RoomHistoryStoreProtocol {
    func save(_ record: RoomHistoryRecord) throws {}

    func fetchAll() throws -> [RoomHistoryRecord] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<10).map { i in
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let scores = [85, 42, 70, 58, 90, 33, 75, 61, 88, 50]
            let ranks = ["A", "D", "B", "C", "A", "E", "B", "C", "A", "C"]
            return RoomHistoryRecord(
                capturedAt: date,
                score: scores[i],
                rank: ranks[i],
                pixelArtImageData: nil
            )
        }
    }
}
