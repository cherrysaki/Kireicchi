import SwiftUI
import AuthenticationServices

struct AppleLoginSection: View {
    @EnvironmentObject var deps: AppDependencies
    @State private var currentRawNonce: String?

    private var isLinkedWithApple: Bool {
        deps.authProvider == "apple.com"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アカウント")
                .font(.headline)
                .padding(.horizontal)

            Group {
                if isLinkedWithApple {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Apple ID でログイン中")
                                .font(.subheadline)
                                .bold()
                            if let name = deps.currentUser?.displayName, !name.isEmpty {
                                Text(name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("データを機種変更時に引き継ぐには Apple ID でログインしてください。")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        .frame(height: 48)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
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
