import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [LatestRoomRecord]

    @AppStorage("selectedCharacterID") private var selectedCharacterTypeRaw: String = CharacterType.character01.rawValue

    @State private var isMissionSheetPresented = false

    private var latestRecord: LatestRoomRecord? { records.first }

    private var selectedCharacterType: CharacterType {
        CharacterType(rawValue: selectedCharacterTypeRaw) ?? .character01
    }

    private var characterState: CharacterState {
        guard let score = latestRecord?.score else { return .happy }
        return CharacterState.fromScore(score)
    }

    private var isRunaway: Bool {
        guard let capturedAt = latestRecord?.capturedAt else { return false }
        let daysSince = Calendar.current.dateComponents([.day], from: capturedAt, to: Date()).day ?? 0
        return daysSince >= 5
    }

    private var pendingMissions: [MissionPersisted] {
        (latestRecord?.missions ?? []).filter { !$0.isDone }
    }

    private var legacyMissionLabels: [String] {
        latestRecord?.messyPointLabels ?? []
    }

    private var pendingMissionCount: Int {
        if !pendingMissions.isEmpty || (latestRecord?.missions.isEmpty == false) {
            return pendingMissions.count
        }
        return legacyMissionLabels.count
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 14) {
                topBar
                statusRow
                roomFrame
                missionBanner
                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .padding(.bottom, 88)

            VStack {
                Spacer()
                HomeTabBar(
                    onHome: { navigationRouter.popToRoot() },
                    onCapture: { navigationRouter.navigate(to: .capture) },
                    onFriends: { navigationRouter.navigate(to: .friendVisit) }
                )
                .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isMissionSheetPresented) {
            HomeMissionSwipeView(
                missions: pendingMissions,
                originalImage: latestRecord?.originalImageData.flatMap { UIImage(data: $0) },
                onComplete: { mission in
                    let store = LatestRoomRecordStore(context: modelContext)
                    try? store.updateMission(id: mission.id, isDone: true)
                }
            )
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                navigationRouter.navigate(to: .settings)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }

            Spacer()

            Text("次の撮影まで  8時間30分")
                .font(DesignSystem.Font.footnote)
                .foregroundColor(DesignSystem.Color.textPrimary)

            Spacer()
                .frame(width: 28)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Status Row (score pill + heart gauge)
    private var statusRow: some View {
        HStack(spacing: 12) {
            scorePill
            heartGaugePill
        }
        .padding(.horizontal, 20)
    }

    private var scorePill: some View {
        HStack(spacing: 8) {
            Text("散らかり指数")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Text(latestRecord.map { "\($0.score)/100" } ?? "--/100")
                .font(DesignSystem.Font.footnote)
                .foregroundColor(DesignSystem.Color.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(DesignSystem.Color.primary)
        )
        .overlay(
            Capsule().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
        )
    }

    private var heartGaugePill: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let value = latestRecord.map {
                Happiness.calculate(
                    score: $0.score,
                    capturedAt: $0.capturedAt,
                    now: context.date
                )
            } ?? Happiness.defaultWhenNoRecord

            HStack(spacing: 8) {
                ZStack {
                    PixelHeartShape().fill(DesignSystem.Color.secondary)
                    PixelHeartStrokeShape().fill(DesignSystem.Color.secondaryDark)
                }
                .frame(width: 22, height: 18)

                GeometryReader { geo in
                    let clamped = min(max(Double(value) / 100.0, 0), 1)
                    ZStack(alignment: .leading) {
                        Capsule().fill(DesignSystem.Color.primary.opacity(0.5))
                        Capsule()
                            .fill(DesignSystem.Color.secondary)
                            .frame(width: geo.size.width * clamped)
                    }
                }
                .frame(height: 14)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(DesignSystem.Color.surface)
            )
            .overlay(
                Capsule().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
            )
        }
    }

    // MARK: - Room Frame
    private var roomFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Color.secondary.opacity(0.15))
                .aspectRatio(1, contentMode: .fit)

            if let data = latestRecord?.pixelArtImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if isRunaway {
                Image("okitegami")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 320)
            } else {
                VStack {
                    Spacer()
                    CharacterView(
                        characterType: selectedCharacterType,
                        characterState: characterState
                    )
                    .frame(width: 200, height: 200)
                    .padding(.bottom, -30)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Color.primary, lineWidth: 5)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Mission Banner
    private var missionBanner: some View {
        Button(action: {
            guard !pendingMissions.isEmpty else { return }
            isMissionSheetPresented = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DesignSystem.Color.surface)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DesignSystem.Color.primaryDark, lineWidth: 1.5)
                        )
                    PixelStar(size: 22)
                }

                Text(missionBannerText)
                    .font(DesignSystem.Font.footnote)
                    .foregroundColor(DesignSystem.Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14).fill(DesignSystem.Color.secondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }

    private var missionBannerText: String {
        let count = pendingMissionCount
        if count > 0 {
            return "ミッションが\(count)件残っています"
        }
        return "撮影してお部屋を分析しよう！"
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationRouter())
            .modelContainer(for: LatestRoomRecord.self, inMemory: true)
    }
}
