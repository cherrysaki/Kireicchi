import SwiftUI

struct AnalysisResultView: View {
    let imageData: Data
    let pixelArtData: Data
    let analysis: RoomAnalysis
    @EnvironmentObject var navigationRouter: NavigationRouter

    private var pixelArtImage: UIImage {
        UIImage(data: pixelArtData) ?? UIImage(systemName: "photo")!
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    rankScoreCard
                    characterCommentRow
                    pixelArtSection
                    priorityListSection
                    actionButtons
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Rank & Score
    private var rankScoreCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("ランク")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                Text(analysis.rank.rawValue)
                    .font(DesignSystem.Font.custom(size: 64))
                    .foregroundColor(colorForScore(analysis.score))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("スコア")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                Text("\(analysis.score)/100")
                    .font(DesignSystem.Font.title)
                    .foregroundColor(DesignSystem.Color.primaryDark)
                Text("ひとことコメント")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    .padding(.top, 6)
                Text(analysis.characterComment)
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .pixelSquareCard(
            fill: DesignSystem.Color.surface,
            border: DesignSystem.Color.primary,
            borderWidth: 3,
            shadowOffset: 4
        )
        .padding(.horizontal)
        .padding(.trailing, 4)
    }

    // MARK: - Character Comment
    private var characterCommentRow: some View {
        HStack(spacing: 12) {
            CharacterView(
                characterType: .character01,
                characterState: nil,
                forceGif: .cheer
            )
            .frame(width: 120, height: 120)

            Text(analysis.characterComment)
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .pixelSquareCard(
                    fill: DesignSystem.Color.secondary.opacity(0.4),
                    border: DesignSystem.Color.primary,
                    borderWidth: 2,
                    shadowOffset: 3
                )

            Spacer()
        }
        .padding(.horizontal)
        .padding(.trailing, 3)
    }

    // MARK: - Pixel Art Section
    private var pixelArtSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ドット絵になったお部屋")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .padding(.horizontal)

            Image(uiImage: pixelArtImage)
                .resizable()
                .interpolation(.none)
                .aspectRatio(1, contentMode: .fit)
                .background(DesignSystem.Color.secondary.opacity(0.2))
                .overlay(
                    Rectangle()
                        .stroke(DesignSystem.Color.primary, lineWidth: 3)
                )
                .padding(.horizontal)
                .padding(.trailing, 4)
        }
    }

    // MARK: - Priority List
    private var priorityListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("片付け優先箇所")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .padding(.horizontal)

            VStack(spacing: 6) {
                ForEach(Array(analysis.messyPoints.prefix(3).enumerated()), id: \.offset) { index, point in
                    HStack(spacing: 12) {
                        ZStack {
                            PixelCircle(pixelSize: 3)
                                .fill(priorityColor(for: index))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(DesignSystem.Font.caption)
                                .foregroundColor(DesignSystem.Color.textOnPrimary)
                        }

                        Text(point.label)
                            .font(DesignSystem.Font.subheadline)
                            .foregroundColor(DesignSystem.Color.textPrimary)

                        Spacer()

                        HStack(spacing: 2) {
                            ForEach(0..<min(max(point.priority, 1), 5), id: \.self) { _ in
                                PixelStar(size: 12)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .pixelSquareCard(
                        fill: DesignSystem.Color.surface,
                        border: DesignSystem.Color.secondary,
                        borderWidth: 2,
                        shadowOffset: 3
                    )
                    .padding(.horizontal)
                    .padding(.trailing, 3)
                }
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button(action: {
                navigationRouter.navigate(to: .cleanupTimer)
            }) {
                HStack {
                    Image(systemName: "timer")
                    Text("お片付けタイマーを始める")
                }
                .font(DesignSystem.Font.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .buttonStyle(PixelButtonStyle())
            .frame(height: 40)
            .padding(.horizontal)
            .padding(.trailing, 4)

            Button(action: {
                navigationRouter.popToRoot()
            }) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("ホームがめんに もどる")
                }
                .font(DesignSystem.Font.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .buttonStyle(PixelButtonStyle(
                fill: DesignSystem.Color.surface,
                foreground: DesignSystem.Color.primaryDark,
                border: DesignSystem.Color.primaryDark,
                borderWidth: 3,
                shadowOffset: 4
            ))
            .frame(height: 40)
            .padding(.horizontal)
            .padding(.trailing, 4)
        }
    }

    private func colorForScore(_ score: Int) -> Color {
        switch score {
        case 85...100: return DesignSystem.Color.primary
        case 70...84:  return DesignSystem.Color.primaryDark
        case 50...69:  return DesignSystem.Color.accent
        case 30...49:  return DesignSystem.Color.accentWarm
        default:       return Color.red
        }
    }

    private func priorityColor(for index: Int) -> Color {
        switch index {
        case 0: return DesignSystem.Color.accentWarm
        case 1: return DesignSystem.Color.accent
        case 2: return DesignSystem.Color.primary
        default: return DesignSystem.Color.secondary
        }
    }

}

#Preview {
    let mockAnalysis = RoomAnalysis(
        score: 75,
        rank: .b,
        messyPoints: [
            MessyPoint(label: "ゆかの ふく", priority: 3),
            MessyPoint(label: "つくえの うえの かみ", priority: 2),
            MessyPoint(label: "ほんだなの せいり", priority: 1)
        ],
        characterComment: "もう少し片付けるといいかも！"
    )
    let dummyImageData = (UIImage(systemName: "photo") ?? UIImage()).pngData() ?? Data()

    NavigationStack {
        AnalysisResultView(
            imageData: dummyImageData,
            pixelArtData: dummyImageData,
            analysis: mockAnalysis
        )
        .environmentObject(NavigationRouter())
    }
}
