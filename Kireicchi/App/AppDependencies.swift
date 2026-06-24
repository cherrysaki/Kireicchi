import Foundation
import Combine
import AuthenticationServices

class MockSignInWithAppleUseCase: SignInWithAppleUseCaseProtocol {
    func makeRawNonce() -> String { "" }
    func hashedNonce(for rawNonce: String) -> String { "" }
    func completeSignIn(authorizationCredential: ASAuthorizationAppleIDCredential, rawNonce: String) async throws -> AppUser {
        return AppUser.makeDefault(uid: "mock", authProvider: "apple.com")
    }
}

@MainActor
final class AppDependencies: ObservableObject {
    @Published var useMockConnectivity: Bool = false
    @Published var currentUser: AppUser? = nil
    @Published var authProvider: String = ""
    @Published var bootstrapError: String? = nil

    let signInWithAppleUseCase: SignInWithAppleUseCaseProtocol
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol

    static let shared = AppDependencies()

    init() {
        let authService = AuthService()
        let userRepository = UserRepository()
        self.authService = authService
        self.userRepository = userRepository
        self.signInWithAppleUseCase = SignInWithAppleUseCase(
            authService: authService,
            userRepository: userRepository
        )
    }

    func bootstrap() async {
        bootstrapError = nil
        do {
            let session = try await authService.ensureSignedIn()
            let user = try await userRepository.createIfMissing(
                uid: session.uid,
                authProvider: session.provider
            )
            self.currentUser = user
            self.authProvider = session.provider
        } catch {
            self.bootstrapError = "サーバーに接続できませんでした (\(error.localizedDescription))"
            print("[bootstrap] failed: \(error)")
        }
    }

    func completeAppleSignIn(credential: ASAuthorizationAppleIDCredential, rawNonce: String) async {
        do {
            let user = try await signInWithAppleUseCase.completeSignIn(
                authorizationCredential: credential,
                rawNonce: rawNonce
            )
            self.currentUser = user
            self.authProvider = user.authProvider
        } catch {
            self.bootstrapError = "Apple サインインに失敗 (\(error.localizedDescription))"
            print("[completeAppleSignIn] failed: \(error)")
        }
    }

    func updateSettings(hour: Int, minute: Int, isEnabled: Bool, characterId: String, username: String) async {
        guard let uid = currentUser?.uid else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let updated = try await userRepository.update(uid: uid) { user in
                user.notificationSettings = NotificationSettingsData(hour: hour, minute: minute, isEnabled: isEnabled)
                user.selectedCharacterId = characterId
                user.username = trimmed.isEmpty ? nil : trimmed
            }
            self.currentUser = updated
        } catch {
            print("[updateSettings] failed: \(error)")
        }
    }

    func updateUsername(_ username: String) async {
        guard let uid = currentUser?.uid else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let updated = try await userRepository.update(uid: uid) { user in
                user.username = trimmed
            }
            self.currentUser = updated
        } catch {
            print("[updateUsername] failed: \(error)")
        }
    }

    func currentOpenAIClient() -> OpenAIClientProtocol {
        OpenAIClient()
    }

    func currentPeerSession() -> PeerSessionProtocol {
        if useMockConnectivity {
            return MockPeerSession()
        } else {
            return PeerSession()
        }
    }

    func currentDistanceTracker() -> NearbyDistanceTrackerProtocol {
        if useMockConnectivity {
            return MockNearbyDistanceTracker()
        } else {
            return NearbyDistanceTracker()
        }
    }

    func makeFriendVisitCoordinator() -> FriendVisitCoordinator {
        FriendVisitCoordinator(
            peerSession: currentPeerSession(),
            distanceTracker: currentDistanceTracker()
        )
    }

    func toggleMockConnectivity() {
        useMockConnectivity.toggle()
    }
}
