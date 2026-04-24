import Foundation
import FirebaseAuth

final class MockAuthService: AuthServiceProtocol {
    private(set) var currentUid: String?
    private var provider: String = "anonymous"

    init(preAuthenticatedUid: String? = nil, provider: String = "anonymous") {
        self.currentUid = preAuthenticatedUid
        self.provider = provider
    }

    func ensureSignedIn() async throws -> AuthSession {
        if let uid = currentUid {
            return AuthSession(uid: uid, provider: provider)
        }
        let uid = "mock-uid-\(UUID().uuidString.prefix(8))"
        currentUid = uid
        provider = "anonymous"
        return AuthSession(uid: uid, provider: provider)
    }

    func linkWithApple(credential: AuthCredential) async throws -> AuthSession {
        guard let uid = currentUid else { throw AuthError.notSignedIn }
        provider = "apple.com"
        return AuthSession(uid: uid, provider: provider)
    }
}
