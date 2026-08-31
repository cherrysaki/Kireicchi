import Foundation
import Combine

@MainActor
protocol PostcardCollectionViewModelProtocol: ObservableObject {
    var records: [PostcardRecord] { get }
    var isSyncing: Bool { get }
    var errorMessage: String? { get set }

    func loadLocal()
    func sync() async
    func delete(_ record: PostcardRecord)
}
