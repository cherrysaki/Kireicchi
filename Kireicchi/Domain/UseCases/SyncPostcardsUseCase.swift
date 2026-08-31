import Foundation

@MainActor
final class SyncPostcardsUseCase: SyncPostcardsUseCaseProtocol {
    private let repository: PostcardRepositoryProtocol

    init(repository: PostcardRepositoryProtocol) {
        self.repository = repository
    }

    func execute(uid: String, store: PostcardStoreProtocol) async throws -> Int {
        let incoming = try await repository.fetchIncoming(uid: uid)
        let existing = try store.existingIds()
        var saved = 0
        for postcard in incoming {
            guard let id = postcard.id else { continue }
            if !existing.contains(id) {
                let imageData = try await repository.downloadImage(path: postcard.imagePath)
                try store.save(PostcardRecord(
                    id: id,
                    fromUid: postcard.fromUid,
                    fromUsername: postcard.fromUsername,
                    score: postcard.score,
                    rank: postcard.rank,
                    imageData: imageData,
                    sentAt: postcard.createdAt
                ))
                saved += 1
            }
            try? await repository.delete(id: id)
        }
        return saved
    }
}
