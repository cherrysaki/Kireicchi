import Foundation

@MainActor
protocol HistoryViewModelProtocol: ObservableObject {
    var records: [RoomHistoryRecord] { get }
    var selectedRecord: RoomHistoryRecord? { get set }
    func loadRecords()
}
