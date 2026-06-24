import Foundation
import AuthenticationServices

protocol SignInWithAppleUseCaseProtocol {
    func makeRawNonce() -> String
    func hashedNonce(for rawNonce: String) -> String
    func completeSignIn(
        authorizationCredential: ASAuthorizationAppleIDCredential,
        rawNonce: String
    ) async throws -> AppUser
}
