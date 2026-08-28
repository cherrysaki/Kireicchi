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

enum InviteCodeError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "InviteCode: サインインされていません"
        }
    }
}

enum ParentLinkError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "ParentLink: サインインされていません"
        }
    }
}

@MainActor
final class AppDependencies: ObservableObject {
    @Published var useMockConnectivity: Bool = false
    @Published var currentUser: AppUser? = nil
    @Published var authProvider: String = ""
    @Published var bootstrapError: String? = nil

    let signInWithAppleUseCase: SignInWithAppleUseCaseProtocol
    let widgetDataStore: KireicchiWidgetDataStoreProtocol
    private let authService: AuthServiceProtocol
    private let userRepository: UserRepositoryProtocol
    private let createInviteCodeUseCase: CreateInviteCodeUseCaseProtocol
    private let unlinkParentUseCase: UnlinkParentUseCaseProtocol
    private let fetchNotificationsUseCase: FetchNotificationsUseCaseProtocol
    private let markNotificationAsReadUseCase: MarkNotificationAsReadUseCaseProtocol

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
        self.widgetDataStore = KireicchiWidgetDataStore()
        self.createInviteCodeUseCase = CreateInviteCodeUseCase(
            repository: InviteCodeRepository()
        )
        self.unlinkParentUseCase = UnlinkParentUseCase(
            repository: ParentLinkRepository()
        )

        // NotificationRepository は fetch/markAsRead で状態を共有する必要があるため、
        // 同一インスタンスを両UseCaseに渡す。.lowScoreWarning は Firestore
        // （dailyCrisisNotifications Cloud Functionが書き込む users/{uid}/appNotifications）
        // に接続済み。.parentMessage/.friendRequest はまだダミーのまま
        // （NotificationRepository内部で保持）。それぞれの実データソースが揃ったら
        // NotificationRepositoryProtocol に準拠した実装への差し替えで個別に対応できる。
        let notificationRepository = NotificationRepository()
        self.fetchNotificationsUseCase = FetchNotificationsUseCase(repository: notificationRepository)
        self.markNotificationAsReadUseCase = MarkNotificationAsReadUseCase(repository: notificationRepository)
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

    func generateInviteCode() async throws -> InviteCode {
        guard let uid = authService.currentUid else {
            throw InviteCodeError.notSignedIn
        }
        return try await createInviteCodeUseCase.execute(childId: uid)
    }

    func unlinkParent() async throws {
        guard authService.currentUid != nil else {
            throw ParentLinkError.notSignedIn
        }
        try await unlinkParentUseCase.execute()
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

    func fetchNotifications() async throws -> [AppNotification] {
        try await fetchNotificationsUseCase.execute()
    }

    func markNotificationAsRead(id: String) async throws {
        try await markNotificationAsReadUseCase.execute(id: id)
    }
}
