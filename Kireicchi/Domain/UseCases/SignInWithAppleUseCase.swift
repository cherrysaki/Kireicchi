import Foundation
import AuthenticationServices
import CryptoKit
import FirebaseAuth

final class SignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol

    init(authService: AuthServiceProtocol, userRepository: UserRepositoryProtocol) {
        self.authService = authService
        self.userRepository = userRepository
    }

    func makeRawNonce() -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = 32
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess { continue }
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    func hashedNonce(for rawNonce: String) -> String {
        let digest = SHA256.hash(data: Data(rawNonce.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func completeSignIn(
        authorizationCredential credential: ASAuthorizationAppleIDCredential,
        rawNonce: String
    ) async throws -> AppUser {
        guard let idTokenData = credential.identityToken,
              let idTokenString = String(data: idTokenData, encoding: .utf8) else {
            throw AuthError.appleIdTokenMissing
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: rawNonce,
            fullName: credential.fullName
        )
        let session = try await authService.linkWithApple(credential: firebaseCredential)

        let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        return try await userRepository.update(uid: session.uid) { user in
            user.authProvider = session.provider
            if !displayName.isEmpty {
                user.displayName = displayName
            }
        }
    }
}
