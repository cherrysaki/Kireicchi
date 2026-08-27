import Foundation

final class CreateInviteCodeUseCase: CreateInviteCodeUseCaseProtocol {
    private let repository: InviteCodeRepositoryProtocol
    private let validDuration: TimeInterval = 10 * 60

    init(repository: InviteCodeRepositoryProtocol) {
        self.repository = repository
    }

    func execute(childId: String) async throws -> InviteCode {
        let code = Self.generateCode()
        let expiresAt = Date().addingTimeInterval(validDuration)
        try await repository.create(code: code, childId: childId, expiresAt: expiresAt)
        return InviteCode(code: code, expiresAt: expiresAt)
    }

    // 紛らわしい文字(0/O, 1/I/L)を除いた英数字から6桁のコードを生成する。
    private static func generateCode(length: Int = 6) -> String {
        let alphabet = Array("ABCDEFGHJKMNPQRSTUVWXYZ23456789")
        return String((0..<length).compactMap { _ in alphabet.randomElement() })
    }
}
