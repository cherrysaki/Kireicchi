import Foundation
import Combine

@MainActor
final class MockPostcardCollectionViewModel: PostcardCollectionViewModelProtocol {
    @Published var records: [PostcardRecord] = [
        PostcardRecord(id: "1", fromUid: "u1", fromUsername: "ぽろこ", score: 88, rank: "A", imageData: Data(), sentAt: Date()),
        PostcardRecord(id: "2", fromUid: "u2", fromUsername: "みなみ", score: 55, rank: "C", imageData: Data(), sentAt: Date().addingTimeInterval(-86400))
    ]
    @Published var isSyncing = false
    @Published var errorMessage: String?

    func loadLocal() {}
    func sync() async {}
    func delete(_ record: PostcardRecord) {
        records.removeAll { $0.id == record.id }
    }
}
