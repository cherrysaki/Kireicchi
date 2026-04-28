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
    @Published var useMockConnectivity: Bool = true
    @Published var currentUser: AppUser? = nil
    @Published var authProvider: String = ""

    var signInWithAppleUseCase: SignInWithAppleUseCaseProtocol

    // Singleton
    static let shared = AppDependencies()

    init() {
        self.signInWithAppleUseCase = MockSignInWithAppleUseCase()
    }

    init(authService: Any, userRepository: Any) {
        self.signInWithAppleUseCase = MockSignInWithAppleUseCase()
    }

    // 起動時の初期化処理
    func bootstrap() async {}

    // Apple Sign In完了処理
    func completeAppleSignIn(credential: Any, rawNonce: String) async {}

    // 設定更新処理
    func updateSettings(hour: Int, minute: Int, isEnabled: Bool, characterId: String) async {}

    func currentOpenAIClient() -> OpenAIClientProtocol {
        OpenAIClient()
    }

    // Mock/Real Connectivityを切り替えるメソッド
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