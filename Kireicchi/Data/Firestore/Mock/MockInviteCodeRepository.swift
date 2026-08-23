import Foundation

final class MockInviteCodeRepository: InviteCodeRepositoryProtocol {
    func create(code: String, childId: String, expiresAt: Date) async throws {}
}
