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
            .frame(width: 80, height: 80)

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
            Text("ドットえに なった おへや")
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
            Text("かたづけ ゆうせん かしょ")
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

                        Text(point)
                            .font(DesignSystem.Font.subheadline)
                            .foregroundColor(DesignSystem.Color.textPrimary)

                        Spacer()

                        Text(starRating(for: index))
                            .font(DesignSystem.Font.caption)
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
                    Text("おかたづけタイマーを はじめる")
                }
                .font(DesignSystem.Font.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(PixelButtonStyle())
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
                .padding(.vertical, 14)
            }
            .buttonStyle(PixelButtonStyle(
                fill: DesignSystem.Color.surface,
                foreground: DesignSystem.Color.primaryDark,
                border: DesignSystem.Color.primaryDark,
                borderWidth: 3,
                shadowOffset: 4
            ))
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

    private func starRating(for index: Int) -> String {
        switch index {
        case 0: return "⭐⭐⭐"
        case 1: return "⭐⭐"
        case 2: return "⭐"
        default: return "⭐"
        }
    }
}

#Preview {
    let mockAnalysis = RoomAnalysis(
        score: 75,
        rank: .b,
        messyPoints: ["ゆかの ふく", "つくえの うえの かみ", "ほんだなの せいり"],
        characterComment: "もう すこし かたづけると いいかも！"
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
