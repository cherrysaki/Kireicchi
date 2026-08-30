import Foundation

/// お知らせ生成に必要な端末側の情報。View が SwiftData / currentUser から組み立てて渡す。
struct NotificationInput {
    var uid: String?
    var reminder: NotificationSettingsData
    var latestScore: Int?
    var latestCapturedAt: Date?
    var receivedPostcards: [ReceivedPostcardSummary]
    var now: Date = Date()

    static func make(
        user: AppUser?,
        latestRecord: LatestRoomRecord?,
        postcards: [PostcardRecord],
        now: Date = Date()
    ) -> NotificationInput {
        NotificationInput(
            uid: user?.uid,
            reminder: user?.notificationSettings ?? .default,
            latestScore: latestRecord?.score,
            latestCapturedAt: latestRecord?.capturedAt,
            receivedPostcards: postcards.map {
                ReceivedPostcardSummary(id: $0.id, fromUsername: $0.fromUsername, sentAt: $0.sentAt)
            },
            now: now
        )
    }
}

struct ReceivedPostcardSummary: Equatable {
    let id: String
    let fromUsername: String
    let sentAt: Date
}
