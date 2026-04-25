import Foundation
import SwiftUI
import Combine
import AuthenticationServices

@MainActor
final class AppDependencies: ObservableObject {
    let authService: AuthServiceProtocol
    let userRepository: UserRepositoryProtocol
    let signInWithAppleUseCase: SignInWithAppleUseCaseProtocol
    let scheduleNotificationUseCase: ScheduleNotificationUseCaseProtocol

    @Published private(set) var currentUid: String?
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var authProvider: String = "anonymous"
    @Published private(set) var isBootstrapping: Bool = false
    @Published private(set) var lastError: String?

    init(
        authService: AuthServiceProtocol = AuthService(),
        userRepository: UserRepositoryProtocol = UserRepository(),
        scheduleNotificationUseCase: ScheduleNotificationUseCaseProtocol = ScheduleNotificationUseCase()
    ) {
        self.authService = authService
        self.userRepository = userRepository
        self.scheduleNotificationUseCase = scheduleNotificationUseCase
        self.signInWithAppleUseCase = SignInWithAppleUseCase(
            authService: authService,
            userRepository: userRepository
        )
    }

    func bootstrap() async {
        guard currentUser == nil else { return }
        isBootstrapping = true
        defer { isBootstrapping = false }
        do {
            let session = try await authService.ensureSignedIn()
            currentUid = session.uid
            authProvider = session.provider
            let user = try await userRepository.createIfMissing(uid: session.uid, authProvider: session.provider)
            currentUser = user
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateSettings(hour: Int, minute: Int, isEnabled: Bool, characterId: String) async {
        guard let uid = currentUid else { return }
        do {
            let updated = try await userRepository.update(uid: uid) { user in
                user.notificationSettings.hour = hour
                user.notificationSettings.minute = minute
                user.notificationSettings.isEnabled = isEnabled
                user.selectedCharacterId = characterId
            }
            currentUser = updated
            await scheduleNotificationUseCase.execute(isEnabled: isEnabled, hour: hour, minute: minute)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func completeAppleSignIn(credential: ASAuthorizationAppleIDCredential, rawNonce: String) async {
        do {
            let user = try await signInWithAppleUseCase.completeSignIn(
                authorizationCredential: credential,
                rawNonce: rawNonce
            )
            currentUser = user
            authProvider = user.authProvider
            currentUid = user.uid
        } catch {
            lastError = error.localizedDescription
        }
    }
}
