import Foundation

final class SendPostcardUseCase: SendPostcardUseCaseProtocol {
    private let repository: PostcardRepositoryProtocol

    init(repository: PostcardRepositoryProtocol) {
        self.repository = repository
    }

    func execute(imageData: Data, from: FriendProfile, to recipients: [FriendProfile], score: Int, rank: String) async throws {
        guard !recipients.isEmpty else { throw PostcardError.noRecipient }
        try await repository.send(imageData: imageData, from: from, to: recipients, score: score, rank: rank)
    }
}
