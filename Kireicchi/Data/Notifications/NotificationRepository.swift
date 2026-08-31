import Foundation
import FirebaseFirestore

/// お知らせの実データを統合する Repository。
/// - friendRequest: Firestore friendRequests（自分宛て・pending）
/// - postcardReceived: 端末コレクション（input.receivedPostcards）＋ Firestore postcards の未取り込み分
/// - captureReminder: 端末内情報（BuildLocalNotificationsUseCase）
/// - lowScoreWarning: Firestore users/{uid}/appNotifications
///   （Cloud Functions の dailyCrisisNotifications が危機レベル「注意」「家出」の間、毎日1件書き込む）
/// - parentMessage: LINE→アプリ経路が未実装のため現状データ源なし
final class NotificationRepository: NotificationRepositoryProtocol {
    private var db: Firestore { Firestore.firestore() }
    private let friendRepository: FriendRepositoryProtocol
    private let postcardRepository: PostcardRepositoryProtocol
    private let readStore: NotificationReadStoreProtocol
    private let buildLocalNotifications: BuildLocalNotificationsUseCaseProtocol
    private let authService: AuthServiceProtocol

    init(
        friendRepository: FriendRepositoryProtocol,
        postcardRepository: PostcardRepositoryProtocol,
        readStore: NotificationReadStoreProtocol,
        buildLocalNotifications: BuildLocalNotificationsUseCaseProtocol,
        authService: AuthServiceProtocol
    ) {
        self.friendRepository = friendRepository
        self.postcardRepository = postcardRepository
        self.readStore = readStore
        self.buildLocalNotifications = buildLocalNotifications
        self.authService = authService
    }

    func fetchAll(input: NotificationInput) async throws -> [AppNotification] {
        var items = buildLocalNotifications.execute(input: input)
        items += postcardNotifications(from: input.receivedPostcards)

        // Firestore 側は失敗しても端末内のお知らせは出す
        if let uid = input.uid {
            do {
                items += try await fetchCrisisNotifications(uid: uid)
            } catch {
                print("[NotificationRepository] appNotifications failed: \(error)")
            }

            do {
                let requests = try await friendRepository.fetchIncomingRequests(uid: uid)
                items += requests.compactMap { request in
                    guard let id = request.id else { return nil }
                    return AppNotification(
                        id: "friendRequest:\(id)",
                        kind: .friendRequest,
                        title: "フレンド申請が届いています",
                        body: "「\(request.fromUsername)」さんからフレンド申請が届いています。",
                        createdAt: request.createdAt,
                        isRead: false
                    )
                }
            } catch {
                print("[NotificationRepository] friend requests failed: \(error)")
            }

            do {
                let knownIds = Set(input.receivedPostcards.map(\.id))
                let pending = try await postcardRepository.fetchIncoming(uid: uid)
                    .filter { $0.id.map { !knownIds.contains($0) } ?? false }
                items += postcardNotifications(from: pending.map {
                    ReceivedPostcardSummary(id: $0.id ?? "", fromUsername: $0.fromUsername, sentAt: $0.createdAt)
                })
            } catch {
                print("[NotificationRepository] postcards failed: \(error)")
            }
        }

        let readIds = readStore.readIds()
        return items
            .map { item in
                var copy = item
                copy.isRead = copy.isRead || readIds.contains(item.id)
                return copy
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func markAsRead(id: String) async throws {
        readStore.markAsRead(id: id)
        // 危機通知（appNotifications 由来）は Firestore 側の isRead も更新する。
        // プレフィックス付きの派生ID（friendRequest: 等）はドキュメントが無いが、無視してよい。
        if let uid = authService.currentUid, !id.contains(":") {
            try? await db.collection("users").document(uid)
                .collection("appNotifications").document(id)
                .updateData(["isRead": true])
        }
    }

    /// dailyCrisisNotifications が書き込む users/{uid}/appNotifications を取得する。
    private func fetchCrisisNotifications(uid: String) async throws -> [AppNotification] {
        let snapshot = try await db.collection("users").document(uid)
            .collection("appNotifications")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let title = data["title"] as? String,
                  let body = data["body"] as? String,
                  let timestamp = data["createdAt"] as? Timestamp else { return nil }
            return AppNotification(
                id: doc.documentID,
                kind: .lowScoreWarning,
                title: title,
                body: body,
                createdAt: timestamp.dateValue(),
                isRead: data["isRead"] as? Bool ?? false
            )
        }
    }

    private func postcardNotifications(from postcards: [ReceivedPostcardSummary]) -> [AppNotification] {
        postcards.map {
            AppNotification(
                id: "postcard:\($0.id)",
                kind: .postcardReceived,
                title: "ポストカードが届きました",
                body: "「\($0.fromUsername)」さんからポストカードが届きました。",
                createdAt: $0.sentAt,
                isRead: false
            )
        }
    }
}
