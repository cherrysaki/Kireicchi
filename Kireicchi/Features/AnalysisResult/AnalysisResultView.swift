import SwiftUI
import SwiftData

struct AnalysisResultView: View {
    let imageData: Data
    let pixelArtData: Data
    let analysis: RoomAnalysis
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [LatestRoomRecord]
    
    private var pixelArtImage: UIImage {
        UIImage(data: pixelArtData) ?? UIImage(systemName: "photo")!
    }
    
    private var originalImage: UIImage? {
        UIImage(data: imageData)
    }
    
    private var allMissions: [MissionPersisted] {
        records.first?.missions ?? []
    }
    
    private var pendingMissions: [MissionPersisted] {
        allMissions.filter { !$0.isDone }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    rankScoreCard
                    characterCommentRow
                    pixelArtSection
                    priorityListSection
                    actionButtons
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Rank & Score
    //    private var rankScoreCard: some View {
    //        HStack(spacing: 16) {
    //            VStack(spacing: 4) {
    //                Text("ランク")
    //                    .font(DesignSystem.Font.caption)
    //                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
    //                Text(analysis.rank.rawValue)
    //                    .font(DesignSystem.Font.custom(size: 64))
    //                    .foregroundColor(colorForScore(analysis.score))
    //            }
    //
    //            VStack(alignment: .leading, spacing: 4) {
    //                Text("スコア")
    //                    .font(DesignSystem.Font.caption)
    //                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
    //                Text("\(analysis.score)/100")
    //                    .font(DesignSystem.Font.title)
    //                    .foregroundColor(DesignSystem.Color.primaryDark)
    //                Text("一言コメント")
    //                    .font(DesignSystem.Font.caption)
    //                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
    //                    .padding(.top, 6)
    //                Text(analysis.characterComment)
    //                    .font(DesignSystem.Font.subheadline)
    //                    .foregroundColor(DesignSystem.Color.textPrimary)
    //                    .lineLimit(2)
    //            }
    //
    //            Spacer()
    //        }
    //        .padding(14)
    //        .pixelSquareCard(
    //            fill: DesignSystem.Color.surface,
    //            border: DesignSystem.Color.primary,
    //            borderWidth: 3,
    //            shadowOffset: 4
    //        )
    //        .padding(.horizontal)
    //        .padding(.trailing, 4)
    //    }
    private var rankScoreCard: some View {
        HStack(spacing: 24) {
//            VStack(spacing: 4) {
//                Text("ランク")
//                    .font(DesignSystem.Font.caption)
//                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                Text(analysis.rank.rawValue)
                    .font(DesignSystem.Font.custom(size: 64))
                    .foregroundColor(colorForScore(analysis.score))
//            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("スコア")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                Text("\(analysis.score)/100")
                    .font(DesignSystem.Font.largeTitle)
                    .foregroundColor(DesignSystem.Color.primaryDark)
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
//        .padding(.trailing, 4)
    }
    // MARK: - Character Comment
    private var characterCommentRow: some View {
        HStack(spacing: 8) {
            CharacterView(
                characterType: .character01,
                characterState: nil,
                forceGif: .cheer
            )
            .frame(width: 160, height: 160)
            
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
//        .padding(.trailing, 3)
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
                .clipShape(PixelCornerRectangle(cornerRadius: 12))
                .overlay(
                    PixelCornerRectangle(cornerRadius: 12)
                        .stroke(DesignSystem.Color.primary, lineWidth: 5)
                )
                .padding(.horizontal)
                .padding(.trailing, 4)
        }
    }
    
    // MARK: - Mission List Section
    private var priorityListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("片付けミッション")
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Spacer()
                if !pendingMissions.isEmpty {
                    Text("\(pendingMissions.count)件残ってる")
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                }
            }
            .padding(.horizontal)
            
            if pendingMissions.isEmpty {
                missionEmptyState
                    .padding(.horizontal)
                    .padding(.trailing, 4)
            } else {
                VStack(spacing: 10) {
                    ForEach(pendingMissions, id: \.id) { mission in
                        MissionListRow(mission: mission) {
                            let store = LatestRoomRecordStore(context: modelContext)
                            try? store.updateMission(id: mission.id, isDone: true)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.trailing, 4)
            }
        }
    }
    
    private var missionEmptyState: some View {
        VStack(spacing: 12) {
            CharacterView(characterType: .character01, characterState: nil, forceGif: .cheer)
                .frame(width: 120, height: 120)
            Text(allMissions.isEmpty ? "きれいなお部屋だね！" : "全部終わった！")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Text(allMissions.isEmpty ? "片付けるところはなかったよ✨" : "お疲れさま✨")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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
                    Text("ホーム画面に戻る")
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

private struct MissionListRow: View {
    let mission: MissionPersisted
    let onComplete: () -> Void
    
    private var starCount: Int { min(max(mission.priority, 1), 5) }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(DesignSystem.Color.primary)
            }
            .buttonStyle(.plain)
            
            Text(mission.label)
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 2) {
                ForEach(0..<starCount, id: \.self) { _ in
                    PixelStar(size: 14)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .pixelSquareCard(
            fill: DesignSystem.Color.surface,
            border: DesignSystem.Color.primary,
            borderWidth: 2,
            shadowOffset: 3
        )
    }
}

#Preview {
    let mockAnalysis = RoomAnalysis(
        score: 75,
        rank: .b,
        messyPoints: [
            MessyPoint(label: "床の服", priority: 3,
                       bbox: NormalizedRect(x: 0.1, y: 0.55, w: 0.45, h: 0.35)),
            MessyPoint(label: "机の上の紙", priority: 2,
                       bbox: NormalizedRect(x: 0.2, y: 0.15, w: 0.4, h: 0.25)),
            MessyPoint(label: "本棚の整理", priority: 1, bbox: nil)
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
