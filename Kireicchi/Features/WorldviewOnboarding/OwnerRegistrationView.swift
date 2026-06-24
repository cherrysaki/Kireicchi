import SwiftUI
import AuthenticationServices

struct OwnerRegistrationView: View {
    @EnvironmentObject private var deps: AppDependencies
    @AppStorage("hasCompletedOwnerRegistration") private var hasCompletedOwnerRegistration: Bool = false

    @State private var step: Int
    @State private var ownerName: String = ""
    @State private var currentRawNonce: String?
    @State private var isSaving = false
    @FocusState private var isNameFocused: Bool

    private let maxLength = 12

    init(step: Int = 1) {
        _step = State(initialValue: step)
    }

    private var trimmedName: String {
        ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            Group {
                if step == 1 {
                    appleSignInStep
                } else {
                    nameInputStep
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }

    // MARK: - Step 1: Apple Sign In

    private var appleSignInStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("きれいっちの育て主登録")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            CharacterView(characterType: .character01, characterState: .happy)
                .frame(width: 200, height: 200)

            Text("きれいっちのお世話をするために、\n育て主の登録をしましょう。")
                .font(DesignSystem.Font.body)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                .multilineTextAlignment(.center)

            Spacer()

            SignInWithAppleButton(
                onRequest: { request in
                    let raw = deps.signInWithAppleUseCase.makeRawNonce()
                    currentRawNonce = raw
                    request.requestedScopes = [.fullName]
                    request.nonce = deps.signInWithAppleUseCase.hashedNonce(for: raw)
                },
                onCompletion: { result in
                    handleAuthorization(result: result)
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Step 2: Owner name

    private var nameInputStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("育て主のなまえを教えてね")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            CharacterView(characterType: .character01, characterState: .happy)
                .frame(width: 200, height: 200)

            TextField("なまえを入力", text: $ownerName)
                .font(DesignSystem.Font.custom(size: 22))
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)
                .focused($isNameFocused)
                .submitLabel(.done)
                .onSubmit(register)
                .onChange(of: ownerName) { _, newValue in
                    if newValue.count > maxLength {
                        ownerName = String(newValue.prefix(maxLength))
                    }
                }
                .padding(14)
                .pixelSquareCard(
                    fill: DesignSystem.Color.surface,
                    border: DesignSystem.Color.primary,
                    borderWidth: 2,
                    shadowOffset: 3
                )
                .padding(.horizontal, 40)
                .padding(.trailing, 3)

            Spacer()

            Button(action: register) {
                Text(isSaving ? "保存中..." : "登録する")
                    .font(DesignSystem.Font.pixelMedium)
                    .frame(width: 240)
                    .padding(.vertical, 14)
            }
            .buttonStyle(PixelButtonStyle())
            .disabled(trimmedName.isEmpty || isSaving)
            .opacity(trimmedName.isEmpty ? 0.5 : 1)
            .padding(.bottom, 48)
        }
        .onAppear { isNameFocused = true }
    }

    // MARK: - Actions

    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let rawNonce = currentRawNonce else { return }
            Task {
                await deps.completeAppleSignIn(credential: credential, rawNonce: rawNonce)
                currentRawNonce = nil
                withAnimation(.easeInOut(duration: 0.35)) {
                    step = 2
                }
            }
        case .failure:
            currentRawNonce = nil
        }
    }

    private func register() {
        let name = trimmedName
        guard !name.isEmpty, !isSaving else { return }
        isSaving = true
        Task {
            await deps.updateUsername(name)
            hasCompletedOwnerRegistration = true
        }
    }
}

#Preview("Step 1: Apple Sign In") {
    OwnerRegistrationView(step: 1)
        .environmentObject(AppDependencies())
}

#Preview("Step 2: Owner Name") {
    OwnerRegistrationView(step: 2)
        .environmentObject(AppDependencies())
}
