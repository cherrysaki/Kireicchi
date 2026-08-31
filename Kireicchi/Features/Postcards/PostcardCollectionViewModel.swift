import Foundation
import Combine

@MainActor
final class PostcardCollectionViewModel: PostcardCollectionViewModelProtocol {
    @Published private(set) var records: [PostcardRecord] = []
    @Published private(set) var isSyncing = false
    @Published var errorMessage: String?

    private let myUid: String?
    private let store: PostcardStoreProtocol
    private let syncPostcardsUseCase: SyncPostcardsUseCaseProtocol

    init(myUid: String?, store: PostcardStoreProtocol, syncPostcardsUseCase: SyncPostcardsUseCaseProtocol) {
        self.myUid = myUid
        self.store = store
        self.syncPostcardsUseCase = syncPostcardsUseCase
    }

    func loadLocal() {
        do {
            records = try store.fetchAll()
        } catch {
            records = []
            print("[PostcardCollectionViewModel] loadLocal failed: \(error)")
        }
    }

    func sync() async {
        guard let uid = myUid else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let saved = try await syncPostcardsUseCase.execute(uid: uid, store: store)
            if saved > 0 { loadLocal() }
        } catch {
            errorMessage = error.localizedDescription
            print("[PostcardCollectionViewModel] sync failed: \(error)")
        }
    }

    func delete(_ record: PostcardRecord) {
        do {
            try store.delete(record)
            loadLocal()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
