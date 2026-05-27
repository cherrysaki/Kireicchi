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
        guard let record = latestRecord else { return .happy }
        let happiness = Happiness.calculate(
            score: record.score,
            capturedAt: record.capturedAt
        )
        return CharacterState.fromHappiness(happiness)
    }

    private func characterState(at now: Date) -> CharacterState {
        guard let record = latestRecord else { return .happy }
        let happiness = Happiness.calculate(
            score: record.score,
            capturedAt: record.capturedAt,
            now: now
        )
        return CharacterState.fromHappiness(happiness)
    }

    private var isRunaway: Bool {
        guard let capturedAt = latestRecord?.capturedAt else { return false }
        let daysSince = Calendar.current.dateComponents([.day], from: capturedAt, to: Date()).day ?? 0
        return daysSince >= 7
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
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    VStack(spacing: 14) {
                        topBar(now: context.date)
                        scorePill
                        roomFrame(now: context.date)
                    }
                }
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
        .sheet(isPresented: $isMissionSheetPresented) {
            MissionListSheet(
                missions: pendingMissions,
                legacyLabels: pendingMissions.isEmpty && latestRecord?.missions.isEmpty != false ? legacyMissionLabels : [],
                onToggleDone: { mission in
                    let store = LatestRoomRecordStore(context: modelContext)
                    try? store.updateMission(id: mission.id, isDone: !mission.isDone)
                }
            )
        }
    }

    // MARK: - Top Bar
    private func topBar(now: Date) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                navigationRouter.navigate(to: .settings)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }

            Spacer()

            Text(nextCaptureText(capturedAt: latestRecord?.capturedAt, now: now))
                .font(DesignSystem.Font.footnote)
                .foregroundColor(DesignSystem.Color.textPrimary)

            Spacer()
                .frame(width: 28)
        }
        .padding(.horizontal, 20)
    }

    private func nextCaptureText(capturedAt: Date?, now: Date) -> String {
        guard let capturedAt else { return "今すぐ撮影しよう！" }
        let next = capturedAt.addingTimeInterval(24 * 3600)
        let remaining = next.timeIntervalSince(now)
        guard remaining > 0 else { return "今すぐ撮影しよう！" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return "次の撮影まで \(hours)時間\(minutes)分"
    }

    private var scorePill: some View {
        HStack {
            Text("散らかり指数")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            Text(latestRecord.map { "\($0.score)/100" } ?? "--/100")
                .font(DesignSystem.Font.title2)
                .bold()
                .foregroundColor(DesignSystem.Color.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignSystem.Color.primary.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Color.primary, lineWidth: 2)
        )
        .padding(.horizontal, 20)
    }

    private func heartGaugePill(now: Date) -> some View {
        let value = latestRecord.map {
            Happiness.calculate(
                score: $0.score,
                capturedAt: $0.capturedAt,
                now: now
            )
        } ?? Happiness.defaultWhenNoRecord

        return HStack(spacing: 6) {
            ZStack {
                PixelHeartShape().fill(DesignSystem.Color.secondary)
                PixelHeartStrokeShape().fill(DesignSystem.Color.secondaryDark)
            }
            .frame(width: 18, height: 14)

            GeometryReader { geo in
                let clamped = min(max(Double(value) / 100.0, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(DesignSystem.Color.primary.opacity(0.3))
                    Capsule()
                        .fill(DesignSystem.Color.secondary)
                        .frame(width: geo.size.width * clamped)
                }
            }
            .frame(width: 80, height: 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(DesignSystem.Color.surface.opacity(0.85))
        )
        .overlay(
            Capsule()
                .stroke(DesignSystem.Color.primaryDark, lineWidth: 1.5)
        )
    }

    // MARK: - Room Frame
    private func roomFrame(now: Date) -> some View {
        ZStack(alignment: .topLeading) {
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
                    .padding(16)
            } else {
                VStack {
                    Spacer()
                    CharacterView(
                        characterType: selectedCharacterType,
                        characterState: characterState(at: now)
                    )
                    .frame(width: 160, height: 160)
                    .padding(.bottom, 8)
                }
            }

            heartGaugePill(now: now)
                .padding(10)
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

// MARK: - Mission List Sheet
private struct MissionListSheet: View {
    let missions: [MissionPersisted]
    let legacyLabels: [String]
    let onToggleDone: (MissionPersisted) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    PixelStar(size: 24)
                    Text("お片付けミッション")
                        .font(DesignSystem.Font.title3)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(DesignSystem.Font.headline)
                            .foregroundColor(DesignSystem.Color.textPrimary)
                    }
                }

                if missions.isEmpty && legacyLabels.isEmpty {
                    Text("まだミッションがありません。\nお部屋を撮影してみよう！")
                        .font(DesignSystem.Font.subheadline)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                } else if !missions.isEmpty {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(missions) { mission in
                                MissionTaskRow(mission: mission) {
                                    onToggleDone(mission)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .pixelSquareCard(
                                    fill: DesignSystem.Color.surface,
                                    border: DesignSystem.Color.primaryDark,
                                    borderWidth: 2,
                                    shadowOffset: 3
                                )
                                .padding(.trailing, 3)
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(legacyLabels.enumerated()), id: \.offset) { index, label in
                                CleanupTaskRow(label: label, index: index)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .pixelSquareCard(
                                        fill: DesignSystem.Color.surface,
                                        border: DesignSystem.Color.primaryDark,
                                        borderWidth: 2,
                                        shadowOffset: 3
                                    )
                                    .padding(.trailing, 3)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Mission Task Row
private struct MissionTaskRow: View {
    let mission: MissionPersisted
    let onToggle: () -> Void

    private var starCount: Int { min(max(mission.priority, 1), 5) }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: mission.isDone ? "checkmark.circle.fill" : "circle")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(mission.isDone ? DesignSystem.Color.primaryDark : DesignSystem.Color.textPrimary.opacity(0.6))
            }
            .buttonStyle(.plain)

            Text(mission.label)
                .font(DesignSystem.Font.subheadline)
                .strikethrough(mission.isDone)
                .foregroundColor(mission.isDone ? DesignSystem.Color.textPrimary.opacity(0.5) : DesignSystem.Color.textPrimary)

            Spacer()

            HStack(spacing: 2) {
                ForEach(0..<starCount, id: \.self) { _ in
                    PixelStar(size: 12)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationRouter())
            .modelContainer(for: LatestRoomRecord.self, inMemory: true)
    }
}
