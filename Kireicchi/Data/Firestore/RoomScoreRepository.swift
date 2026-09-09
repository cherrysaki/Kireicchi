import Foundation
import FirebaseFirestore
import FirebaseStorage

/// users/{uid}/roomScores/{scoreId} にスコアを追記する。
/// 接続先はその時点でアクティブな FirebaseApp（既定アプリ）に従うため、
/// 環境（Dev: kireicchiparent-dev / 本番: kireicchi）を意識しない実装になっている。
final class RoomScoreRepository: RoomScoreRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }
    private var storage: Storage { Storage.storage() }

    func save(uid: String, score: Int, rank: String, pixelArtImageData: Data?) async throws {
        let docRef = db.collection("users").document(uid)
            .collection("roomScores")
            .document()

        var data: [String: Any] = [
            "score": score,
            "rank": rank,
            "createdAt": FieldValue.serverTimestamp()
        ]

        if let pixelArtImageData {
            if let imagePath = try? await uploadPixelArt(pixelArtImageData, uid: uid, docId: docRef.documentID) {
                data["imagePath"] = imagePath
            } else {
                print("[roomScore] ドット絵のStorageアップロードに失敗したため imagePath なしで保存します")
            }
        }

        try await docRef.setData(data)
    }

    private func uploadPixelArt(_ imageData: Data, uid: String, docId: String) async throws -> String {
        let path = "roomScores/\(uid)/\(docId).png"
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        _ = try await storage.reference(withPath: path).putDataAsync(imageData, metadata: metadata)
        return path
    }
}
