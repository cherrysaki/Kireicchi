import Foundation
import Combine

@MainActor
final class MockHistoryViewModel: HistoryViewModelProtocol, ObservableObject {
    @Published var records: [RoomHistoryRecord] = []
    @Published var selectedRecord: RoomHistoryRecord?

    private let historyStore: RoomHistoryStoreProtocol

    init(historyStore: RoomHistoryStoreProtocol? = nil) {
        self.historyStore = historyStore ?? MockRoomHistoryStore()
        loadRecords()
    }

    func loadRecords() {
        records = (try? historyStore.fetchAll()) ?? []
    }
}
