import Foundation

/// 親子連携用の招待コードを Firestore の inviteCodes/{code} に作成する。
protocol InviteCodeRepositoryProtocol: Sendable {
    func create(code: String, childId: String, expiresAt: Date) async throws
}
