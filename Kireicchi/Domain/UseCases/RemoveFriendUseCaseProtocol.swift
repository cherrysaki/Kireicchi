import Foundation

protocol RemoveFriendUseCaseProtocol {
    func execute(uid: String, friendUid: String) async throws
}
