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
    private let userIdRepository: UserIdRepositoryProtocol
    private let fetchFriendsUseCase: FetchFriendsUseCaseProtocol
    private let searchFriendUseCase: SearchFriendUseCaseProtocol
    private let sendFriendRequestUseCase: SendFriendRequestUseCaseProtocol
    private let respondFriendRequestUseCase: RespondFriendRequestUseCaseProtocol
    private let cancelFriendRequestUseCase: CancelFriendRequestUseCaseProtocol
    private let removeFriendUseCase: RemoveFriendUseCaseProtocol
    private let sendPostcardUseCase: SendPostcardUseCaseProtocol
    private let syncPostcardsUseCase: SyncPostcardsUseCaseProtocol

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

        let userIdRepository = UserIdRepository()
        let friendRepository = FriendRepository()
        let postcardRepository = PostcardRepository()

        // .lowScoreWarning は dailyCrisisNotifications Cloud Function が書き込む
        // users/{uid}/appNotifications、友達申請・ポストカードは各Repository、
        // 撮影リマインダーは端末内判定から統合して取得する。
        let notificationRepository = NotificationRepository(
            friendRepository: friendRepository,
            postcardRepository: postcardRepository,
            readStore: NotificationReadStore(),
            buildLocalNotifications: BuildLocalNotificationsUseCase(),
            authService: authService
        )
        self.fetchNotificationsUseCase = FetchNotificationsUseCase(repository: notificationRepository)
        self.markNotificationAsReadUseCase = MarkNotificationAsReadUseCase(repository: notificationRepository)

        self.userIdRepository = userIdRepository
        self.fetchFriendsUseCase = FetchFriendsUseCase(repository: friendRepository)
        self.searchFriendUseCase = SearchFriendUseCase(repository: userIdRepository)
        self.sendFriendRequestUseCase = SendFriendRequestUseCase(repository: friendRepository)
        self.respondFriendRequestUseCase = RespondFriendRequestUseCase(repository: friendRepository)
        self.cancelFriendRequestUseCase = CancelFriendRequestUseCase(repository: friendRepository)
        self.removeFriendUseCase = RemoveFriendUseCase(repository: friendRepository)

        self.sendPostcardUseCase = SendPostcardUseCase(repository: postcardRepository)
        self.syncPostcardsUseCase = SyncPostcardsUseCase(repository: postcardRepository)
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
            await ensureUserId(user)
        } catch {
            self.bootstrapError = "サーバーに接続できませんでした (\(error.localizedDescription))"
            print("[bootstrap] failed: \(error)")
        }
    }

    /// ユーザーIDが未発行なら生成して users/{uid}.userId に保存する（失敗時はログのみ）。
    private func ensureUserId(_ user: AppUser) async {
        guard let uid = user.uid, user.userId == nil else { return }
        do {
            let userId = try await userIdRepository.generateAndReserve(uid: uid)
            let updated = try await userRepository.update(uid: uid) { $0.userId = userId }
            self.currentUser = updated
        } catch {
            print("[bootstrap] userId issue failed: \(error)")
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

    /// ユーザーIDを変更する場合、他人が使用中なら FriendError.userIdTaken、形式不正なら FriendError.invalidUserId を投げる。
    func updateSettings(hour: Int, minute: Int, isEnabled: Bool, characterId: String, username: String, userId: String) async throws {
        guard let uid = currentUser?.uid else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedUserId = UserIdRepository.normalize(userId)
        let currentUserId = currentUser?.userId
        if !normalizedUserId.isEmpty, normalizedUserId != currentUserId {
            try await userIdRepository.change(to: normalizedUserId, uid: uid, previousUserId: currentUserId)
        }
        let updated = try await userRepository.update(uid: uid) { user in
            user.notificationSettings = NotificationSettingsData(hour: hour, minute: minute, isEnabled: isEnabled)
            user.selectedCharacterId = characterId
            user.username = trimmed.isEmpty ? nil : trimmed
            if !normalizedUserId.isEmpty { user.userId = normalizedUserId }
        }
        self.currentUser = updated
    }

    func updateUsername(_ username: String) async throws {
        guard let uid = currentUser?.uid else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let updated = try await userRepository.update(uid: uid) { user in
            user.username = trimmed
        }
        self.currentUser = updated
    }

    var myFriendProfile: FriendProfile? {
        guard let user = currentUser, let uid = user.uid else { return nil }
        guard let username = user.username, !username.isEmpty else { return nil }
        return FriendProfile(uid: uid, username: username, selectedCharacterId: user.selectedCharacterId, userId: user.userId)
    }

    func makeFriendsViewModel() -> FriendsViewModel {
        FriendsViewModel(
            myProfile: myFriendProfile,
            myUid: currentUser?.uid,
            fetchFriendsUseCase: fetchFriendsUseCase,
            searchFriendUseCase: searchFriendUseCase,
            sendFriendRequestUseCase: sendFriendRequestUseCase,
            respondFriendRequestUseCase: respondFriendRequestUseCase,
            cancelFriendRequestUseCase: cancelFriendRequestUseCase,
            removeFriendUseCase: removeFriendUseCase
        )
    }

    func makeSendPostcardViewModel(pixelArtData: Data, analysis: RoomAnalysis) -> SendPostcardViewModel {
        let characterRaw = UserDefaults.standard.string(forKey: "selectedCharacterID") ?? CharacterType.character01.rawValue
        return SendPostcardViewModel(
            pixelArtData: pixelArtData,
            score: analysis.score,
            rank: analysis.rank.rawValue,
            characterType: CharacterType(rawValue: characterRaw) ?? .character01,
            characterState: analysis.characterState,
            myProfile: myFriendProfile,
            fetchFriendsUseCase: fetchFriendsUseCase,
            sendPostcardUseCase: sendPostcardUseCase,
            composePostcardImageUseCase: ComposePostcardImageUseCase()
        )
    }

    func makePostcardCollectionViewModel(store: PostcardStoreProtocol) -> PostcardCollectionViewModel {
        PostcardCollectionViewModel(
            myUid: currentUser?.uid,
            store: store,
            syncPostcardsUseCase: syncPostcardsUseCase
        )
    }

    func fetchIncomingFriendRequestCount() async throws -> Int {
        guard let uid = currentUser?.uid else { return 0 }
        return try await fetchFriendsUseCase.execute(uid: uid).incomingRequests.count
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


    func fetchNotifications(input: NotificationInput) async throws -> [AppNotification] {
        try await fetchNotificationsUseCase.execute(input: input)
    }

    func markNotificationAsRead(id: String) async throws {
        try await markNotificationAsReadUseCase.execute(id: id)
    }
}
