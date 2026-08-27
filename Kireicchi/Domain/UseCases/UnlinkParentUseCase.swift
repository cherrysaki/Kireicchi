import Foundation

final class UnlinkParentUseCase: UnlinkParentUseCaseProtocol {
    private let repository: ParentLinkRepositoryProtocol

    init(repository: ParentLinkRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.unlink()
    }
}
