import Foundation
import FirebaseAuth

struct AuthSession: Equatable {
    let uid: String
    let provider: String
}

protocol AuthServiceProtocol {
    var currentUid: String? { get }
    func ensureSignedIn() async throws -> AuthSession
    func linkWithApple(credential: AuthCredential) async throws -> AuthSession
}

enum AuthError: LocalizedError {
    case notSignedIn
    case appleIdTokenMissing

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Auth: サインインされていません"
        case .appleIdTokenMissing: return "Auth: Apple ID トークンが取得できませんでした"
        }
    }
}
