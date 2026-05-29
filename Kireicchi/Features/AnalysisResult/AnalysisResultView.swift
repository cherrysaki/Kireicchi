import SwiftUI
import SwiftData

struct AnalysisResultView: View {
    let imageData: Data
    let pixelArtData: Data
    let analysis: RoomAnalysis
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [LatestRoomRecord]

    @State private var skippedIds: Set<String> = []

    private var pixelArtImage: UIImage {
        UIImage(data: pixelArtData) ?? UIImage(systemName: "photo")!
    }

    private var originalImage: UIImage? {
        UIImage(data: imageData)
    }

    private var pendingMissions: [MissionPersisted] {
        (records.first?.missions ?? []).filter {
            !$0.isDone && !skippedIds.contains($0.id)
        }
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(DesignSystem.Color.primary, lineWidth: 5)
                )
                .padding(.horizontal)
                .padding(.trailing, 4)
        }
    }

    // MARK: - Mission Swipe Section
    private var priorityListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("片付けミッション")
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Spacer()
                if !pendingMissions.isEmpty {
                    Text("\(pendingMissions.count)件のこってる")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                }
            }
            .padding(.horizontal)

            SwipeMissionStack(
                missions: pendingMissions,
                originalImage: originalImage,
                onSwipe: { mission, direction in
                    if direction == .right {
                        let store = LatestRoomRecordStore(context: modelContext)
                        try? store.updateMission(id: mission.id, isDone: true)
                    } else {
                        skippedIds.insert(mission.id)
                    }
                }
            )
            .frame(height: 420)
            .padding(.horizontal)
            .padding(.trailing, 6)

            if !pendingMissions.isEmpty {
                Text("← スキップ        DONE →")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
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

}

#Preview {
    let mockAnalysis = RoomAnalysis(
        score: 75,
        rank: .b,
        messyPoints: [
            MessyPoint(label: "ゆかの ふく", priority: 3,
                       bbox: NormalizedRect(x: 0.1, y: 0.55, w: 0.45, h: 0.35)),
            MessyPoint(label: "つくえの うえの かみ", priority: 2,
                       bbox: NormalizedRect(x: 0.2, y: 0.15, w: 0.4, h: 0.25)),
            MessyPoint(label: "ほんだなの せいり", priority: 1, bbox: nil)
        ],
        characterComment: "もう少し片付けるといいかも！"
    )
    let dummyImage = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600)).image { ctx in
        UIColor.systemTeal.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 600))
        UIColor.systemOrange.setFill()
        ctx.fill(CGRect(x: 60, y: 330, width: 270, height: 210))
    }
    let dummyImageData = dummyImage.pngData() ?? Data()

    let container = try! ModelContainer(
        for: LatestRoomRecord.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let missions = mockAnalysis.messyPoints.map { MissionPersisted(from: $0) }
    let missionsData = try? JSONEncoder().encode(missions)
    container.mainContext.insert(LatestRoomRecord(
        pixelArtImageData: dummyImageData,
        capturedAt: Date(),
        score: mockAnalysis.score,
        comment: mockAnalysis.characterComment,
        messyPointLabels: missions.map { "\($0.label):\($0.priority)" },
        originalImageData: dummyImageData,
        missionsData: missionsData
    ))

    return NavigationStack {
        AnalysisResultView(
            imageData: dummyImageData,
            pixelArtData: dummyImageData,
            analysis: mockAnalysis
        )
        .environmentObject(NavigationRouter())
        .modelContainer(container)
    }
}
