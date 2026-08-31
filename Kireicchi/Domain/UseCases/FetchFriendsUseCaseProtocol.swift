import Foundation

protocol FetchFriendsUseCaseProtocol {
    func execute(uid: String) async throws -> FriendsSnapshot
}
