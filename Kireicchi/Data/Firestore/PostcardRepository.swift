import Foundation
import FirebaseFirestore
import FirebaseStorage

final class PostcardRepository: PostcardRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }
    private var storage: Storage { Storage.storage() }
    private var postcards: CollectionReference { db.collection("postcards") }

    private static let maxImageBytes: Int64 = 1024 * 1024

    func send(imageData: Data, from: FriendProfile, to recipients: [FriendProfile], score: Int, rank: String) async throws {
        guard !recipients.isEmpty else { return }

        let imageId = UUID().uuidString
        let imagePath = "postcards/\(from.uid)/\(imageId).png"
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        _ = try await storage.reference(withPath: imagePath).putDataAsync(imageData, metadata: metadata)

        let now = Date()
        let batch = db.batch()
        for recipient in recipients {
            let postcard = Postcard(
                fromUid: from.uid,
                fromUsername: from.username,
                toUid: recipient.uid,
                imagePath: imagePath,
                score: score,
                rank: rank,
                createdAt: now
            )
            try batch.setData(from: postcard, forDocument: postcards.document())
        }
        try await batch.commit()
    }

    func fetchIncoming(uid: String) async throws -> [Postcard] {
        let snapshot = try await postcards
            .whereField("toUid", isEqualTo: uid)
            .getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: Postcard.self) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func downloadImage(path: String) async throws -> Data {
        try await storage.reference(withPath: path).data(maxSize: Self.maxImageBytes)
    }

    func delete(id: String) async throws {
        try await postcards.document(id).delete()
    }
}
