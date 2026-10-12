import SwiftUI

struct CharacterChoiceCard: View {
    let characterType: CharacterType
    let isSelected: Bool
    var showsIntroduction = true
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    AnimatedGIFView(assetName: "\(characterType.rawValue)_portrait")
                    .frame(height: showsIntroduction ? 110 : 82)
                    .accessibilityHidden(true)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(DesignSystem.Color.primary)
                            .background(Circle().fill(DesignSystem.Color.surface))
                    }
                }

                Text(characterType.displayName)
                    .font(showsIntroduction ? DesignSystem.Font.pixelMedium : DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary)

                if showsIntroduction {
                    Text(characterType.introduction)
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(minHeight: 34)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .pixelSquareCard(
                fill: DesignSystem.Color.surface,
                border: isSelected ? DesignSystem.Color.primary : DesignSystem.Color.textPrimary.opacity(0.2),
                borderWidth: isSelected ? 3 : 2,
                shadowOffset: isSelected ? 4 : 2
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(characterType.displayName)、\(characterType.introduction)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    CharacterChoiceCard(characterType: .character03, isSelected: true, select: {})
        .frame(width: 170)
        .padding()
}
