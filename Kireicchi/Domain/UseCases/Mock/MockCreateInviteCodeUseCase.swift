import Foundation

final class MockCreateInviteCodeUseCase: CreateInviteCodeUseCaseProtocol {
    func execute(childId: String) async throws -> InviteCode {
        InviteCode(code: "ABC123", expiresAt: Date().addingTimeInterval(600))
    }
}
