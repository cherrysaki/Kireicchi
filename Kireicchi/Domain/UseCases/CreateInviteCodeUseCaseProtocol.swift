import Foundation

struct InviteCode: Equatable {
    let code: String
    let expiresAt: Date
}

protocol CreateInviteCodeUseCaseProtocol {
    func execute(childId: String) async throws -> InviteCode
}
