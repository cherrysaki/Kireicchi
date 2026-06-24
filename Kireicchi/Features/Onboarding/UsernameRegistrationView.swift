import SwiftUI

struct UsernameRegistrationView: View {
    @EnvironmentObject private var deps: AppDependencies
    @AppStorage("hasRegisteredUsername") private var hasRegisteredUsername: Bool = false

    @State private var username: String = ""
    @State private var isSaving = false
    @FocusState private var isFocused: Bool

    private let maxLength = 12

    private var trimmedName: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                CharacterView(characterType: .character01, characterState: .happy)
                    .frame(width: 220, height: 220)

                VStack(spacing: 8) {
                    Text("名前をおしえてね")
                        .font(DesignSystem.Font.title2)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                    Text("きれいっちが あなたを\nなんて 呼べばいいかな？")
                        .font(DesignSystem.Font.subheadline)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                TextField("ユーザーネーム", text: $username)
                    .font(DesignSystem.Font.custom(size: 22))
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(register)
                    .onChange(of: username) { _, newValue in
                        if newValue.count > maxLength {
                            username = String(newValue.prefix(maxLength))
                        }
                    }
                    .padding(14)
                    .pixelSquareCard(
                        fill: DesignSystem.Color.surface,
                        border: DesignSystem.Color.primary,
                        borderWidth: 2,
                        shadowOffset: 3
                    )
                    .padding(.horizontal, 32)
                    .padding(.trailing, 3)

                Spacer()

                Button(action: register) {
                    Text(isSaving ? "保存中..." : "決定")
                        .font(DesignSystem.Font.pixelMedium)
                        .frame(width: 240)
                        .padding(.vertical, 14)
                }
                .buttonStyle(PixelButtonStyle())
                .disabled(trimmedName.isEmpty || isSaving)
                .opacity(trimmedName.isEmpty ? 0.3 : 1)
                .frame(width: 320, height: 56)
                .padding(.bottom, 172)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: skip) {
                        Text("スキップ")
                            .font(DesignSystem.Font.footnote)
                            .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .disabled(isSaving)
                }
                Spacer()
            }
        }
        .onAppear { isFocused = true }
    }

    private func register() {
        let name = trimmedName
        guard !name.isEmpty, !isSaving else { return }
        isSaving = true
        Task {
            await deps.updateUsername(name)
            hasRegisteredUsername = true
        }
    }

    private func skip() {
        hasRegisteredUsername = true
    }
}

#Preview {
    UsernameRegistrationView()
        .environmentObject(AppDependencies())
}
