import SwiftUI

struct OwnerRegistrationView: View {
    @EnvironmentObject private var deps: AppDependencies
    @AppStorage("hasCompletedOwnerRegistration") private var hasCompletedOwnerRegistration: Bool = false

    @State private var ownerName: String = ""
    @State private var isSaving = false
    @FocusState private var isNameFocused: Bool

    private let maxLength = 12

    private var trimmedName: String {
        ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("きれいっちの飼い主登録")
                    .font(DesignSystem.Font.title2)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                CharacterView(characterType: .character01, characterState: .happy)
                    .frame(width: 160, height: 160)

                Text("あなたのなまえを教えてね！")
                    .font(DesignSystem.Font.body)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)

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
                    Text(isSaving ? "保存中..." : "登録")
                        .font(DesignSystem.Font.pixelMedium)
                        .frame(width: 240)
                        .padding(.vertical, 10)
                }
                .buttonStyle(PixelButtonStyle())
                .disabled(trimmedName.isEmpty || isSaving)
                .opacity(trimmedName.isEmpty ? 0.5 : 1)
                .padding(.bottom, 48)
            }
        }
        .onAppear { isNameFocused = true }
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

#Preview {
    OwnerRegistrationView()
        .environmentObject(AppDependencies())
}
