import SwiftUI

struct CharacterSelectionView: View {
    @EnvironmentObject private var deps: AppDependencies
    @AppStorage("selectedCharacterID") private var selectedCharacterID = CharacterType.character01.rawValue
    @AppStorage("hasSelectedInitialCharacter") private var hasSelectedInitialCharacter = false

    @State private var selection: CharacterType = .character01
    @State private var isSaving = false

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("いっしょに暮らす子をえらんでね")
                        .font(DesignSystem.Font.title2)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text("あとから変更することもできます")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.65))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(CharacterType.allCases, id: \.self) { characterType in
                            CharacterChoiceCard(characterType: characterType, isSelected: selection == characterType) {
                                selection = characterType
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: confirmSelection) {
                    Text(isSaving ? "お迎え中..." : "この子に決める")
                        .font(DesignSystem.Font.pixelMedium)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 260, height: 52)
                .buttonStyle(PixelButtonStyle())
                .disabled(isSaving)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(DesignSystem.Color.background)
            }
        }
        .onAppear {
            selection = CharacterType(rawValue: selectedCharacterID) ?? .character01
        }
    }

    private func confirmSelection() {
        guard !isSaving else { return }
        isSaving = true
        selectedCharacterID = selection.rawValue

        Task {
            await deps.updateSelectedCharacter(selection)
            hasSelectedInitialCharacter = true
            isSaving = false
        }
    }
}

#Preview {
    CharacterSelectionView()
        .environmentObject(AppDependencies())
}
