import Foundation

final class NotificationRepository: NotificationRepositoryProtocol {
    private let friendRepository: FriendRepositoryProtocol
    private let postcardRepository: PostcardRepositoryProtocol
    private let readStore: NotificationReadStoreProtocol
    private let buildLocalNotifications: BuildLocalNotificationsUseCaseProtocol

    init(
        friendRepository: FriendRepositoryProtocol,
        postcardRepository: PostcardRepositoryProtocol,
        readStore: NotificationReadStoreProtocol,
        buildLocalNotifications: BuildLocalNotificationsUseCaseProtocol
    ) {
        self.friendRepository = friendRepository
        self.postcardRepository = postcardRepository
        self.readStore = readStore
        self.buildLocalNotifications = buildLocalNotifications
    }

    func fetchAll(input: NotificationInput) async throws -> [AppNotification] {
        var items = buildLocalNotifications.execute(input: input)
        items += postcardNotifications(from: input.receivedPostcards)

        // Firestore 側は失敗しても端末内のお知らせは出す
        if let uid = input.uid {
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
                copy.isRead = readIds.contains(item.id)
                return copy
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func markAsRead(id: String) async throws {
        readStore.markAsRead(id: id)
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
