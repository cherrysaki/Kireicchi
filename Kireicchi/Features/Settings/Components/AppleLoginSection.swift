import SwiftUI
import AuthenticationServices

struct AppleLoginSection: View {
    @EnvironmentObject var deps: AppDependencies
    @State private var currentRawNonce: String?

    private var isLinkedWithApple: Bool {
        deps.authProvider == "apple.com"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("アカウント")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .padding(.horizontal)

            Group {
                if isLinkedWithApple {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(DesignSystem.Color.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple ID でログイン中")
                                .font(DesignSystem.Font.subheadline)
                                .foregroundColor(DesignSystem.Color.textPrimary)
                            if let name = deps.currentUser?.displayName, !name.isEmpty {
                                Text(name)
                                    .font(DesignSystem.Font.caption)
                                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                            }
                        }
                        Spacer()
                    }
                    .padding(14)
                    .pixelSquareCard(
                        fill: DesignSystem.Color.surface,
                        border: DesignSystem.Color.primary,
                        borderWidth: 2,
                        shadowOffset: 3
                    )
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("きしゅへんこうの ときに データを ひきつぐには Apple ID で ログインしてください。")
                            .font(DesignSystem.Font.caption)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                        SignInWithAppleButton(
                            onRequest: { request in
                                let raw = deps.signInWithAppleUseCase.makeRawNonce()
                                currentRawNonce = raw
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = deps.signInWithAppleUseCase.hashedNonce(for: raw)
                            },
                            onCompletion: { result in
                                handleAuthorization(result: result)
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 44)
                    }
                    .padding(14)
                    .pixelSquareCard(
                        fill: DesignSystem.Color.surface,
                        border: DesignSystem.Color.primary,
                        borderWidth: 2,
                        shadowOffset: 3
                    )
                }
            }
            .padding(.horizontal)
            .padding(.trailing, 3)
        }
    }

    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let rawNonce = currentRawNonce else { return }
            Task {
                await deps.completeAppleSignIn(credential: credential, rawNonce: rawNonce)
                currentRawNonce = nil
            }
        case .failure:
            currentRawNonce = nil
        }
    }
}

#Preview {
    AppleLoginSection()
        .environmentObject(AppDependencies(
            authService: MockAuthService(preAuthenticatedUid: "mock-uid"),
            userRepository: MockUserRepository()
        ))
}
