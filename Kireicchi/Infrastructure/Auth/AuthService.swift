import Foundation
import FirebaseAuth

final class AuthService: AuthServiceProtocol {
    var currentUid: String? { Auth.auth().currentUser?.uid }

    func ensureSignedIn() async throws -> AuthSession {
        if let user = Auth.auth().currentUser {
            return AuthSession(uid: user.uid, provider: Self.providerString(for: user))
        }
        let result = try await Auth.auth().signInAnonymously()
        return AuthSession(uid: result.user.uid, provider: "anonymous")
    }

    func linkWithApple(credential: AuthCredential) async throws -> AuthSession {
        guard let user = Auth.auth().currentUser else { throw AuthError.notSignedIn }
        let result = try await user.link(with: credential)
        return AuthSession(uid: result.user.uid, provider: Self.providerString(for: result.user))
    }

    private static func providerString(for user: User) -> String {
        if user.isAnonymous { return "anonymous" }
        return user.providerData.first?.providerID ?? "unknown"
    }
}
