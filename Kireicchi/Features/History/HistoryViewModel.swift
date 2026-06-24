import Foundation
import Combine

@MainActor
final class HistoryViewModel: HistoryViewModelProtocol, ObservableObject {
    @Published var records: [RoomHistoryRecord] = []
    @Published var selectedRecord: RoomHistoryRecord?

    private let historyStore: RoomHistoryStoreProtocol

    init(historyStore: RoomHistoryStoreProtocol) {
        self.historyStore = historyStore
    }

    func loadRecords() {
        do {
            records = try historyStore.fetchAll()
        } catch {
            records = []
        }
    }
}
