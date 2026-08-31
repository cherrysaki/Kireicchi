import Foundation

final class MockFCMTokenRepository: FCMTokenRepositoryProtocol {
    func save(uid: String, token: String) async throws {}
}
