import Foundation

protocol SendPostcardUseCaseProtocol {
    func execute(imageData: Data, from: FriendProfile, to recipients: [FriendProfile], score: Int, rank: String) async throws
}
