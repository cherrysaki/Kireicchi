import Foundation
import SwiftData

/// 受け取ったポストカード（コレクション）。id は Firestore の postcardId。
@Model
final class PostcardRecord {
    @Attribute(.unique) var id: String
    var fromUid: String
    var fromUsername: String
    var score: Int
    var rank: String
    var imageData: Data
    var sentAt: Date
    var receivedAt: Date

    init(id: String, fromUid: String, fromUsername: String, score: Int, rank: String,
         imageData: Data, sentAt: Date, receivedAt: Date = Date()) {
        self.id = id
        self.fromUid = fromUid
        self.fromUsername = fromUsername
        self.score = score
        self.rank = rank
        self.imageData = imageData
        self.sentAt = sentAt
        self.receivedAt = receivedAt
    }
}
