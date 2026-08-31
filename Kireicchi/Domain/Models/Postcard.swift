import Foundation
import FirebaseFirestore

/// Firestore postcards/{postcardId}。画像本体は Storage の imagePath に置く。
struct Postcard: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var fromUid: String
    var fromUsername: String
    var toUid: String
    var imagePath: String
    var score: Int
    var rank: String
    var createdAt: Date
}
