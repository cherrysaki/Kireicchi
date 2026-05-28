import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Environment(\.modelContext) private var modelContext
    @Query private var records: [LatestRoomRecord]
    @Query private var historyRecords: [RoomHistoryRecord]

    @AppStorage("selectedCharacterID") private var selectedCharacterTypeRaw: String = CharacterType.character01.rawValue

    @State private var isMissionSheetPresented = false
    @State private var showCaptureAlert: Bool = false

    private var todayCaptureCount: Int {
        let calendar = Calendar.current
        return historyRecords.filter {
            calendar.isDateInToday($0.capturedAt)
        }.count
    }

    private var canCapture: Bool {
        todayCaptureCount < 2
    }

    private var latestRecord: LatestRoomRecord? { records.first }

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

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 14) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    VStack(spacing: 14) {
                        topBar(now: context.date)
                        statusRow(now: context.date)
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
                    onCapture: {
                        if canCapture {
                            navigationRouter.navigate(to: .capture)
                        } else {
                            showCaptureAlert = true
                        }
                    },
                    onFriends: { navigationRouter.navigate(to: .friendVisit) },
                    canCapture: canCapture
                )
                .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
        .alert("本日の撮影は終了しました", isPresented: $showCaptureAlert) {
            Button("OK") {}
        } message: {
            Text("1日2回まで撮影できます。\nまた明日撮影してね！")
        }
        .sheet(isPresented: $isMissionSheetPresented) {
            MissionListSheet(
                missions: pendingMissions,
                legacyLabels: pendingMissions.isEmpty && latestRecord?.missions.isEmpty != false
                    ? legacyMissionLabels : [],
                onToggleDone: { mission in
                    let store = LatestRoomRecordStore(context: modelContext)
                    try? store.updateMission(id: mission.id, isDone: !mission.isDone)
                }
            )
        }
    }

    // MARK: - Top Bar
    private func topBar(now: Date) -> some View {
        ZStack {
            Text(nextCaptureText(capturedAt: latestRecord?.capturedAt, now: now))
                .font(DesignSystem.Font.footnote)
                .foregroundColor(DesignSystem.Color.textPrimary)

            HStack {
                Button(action: {
                    navigationRouter.navigate(to: .settings)
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(DesignSystem.Font.title3)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                }
                Spacer()
            }
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

    // MARK: - Status Row (score pill のみ、ハートゲージは roomFrame にオーバーレイ)
    private func statusRow(now: Date) -> some View {
        scorePill
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
    }

    private var scorePill: some View {
        HStack(spacing: 8) {
            Text("散らかり指数")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            Text(latestRecord.map { "\($0.score)/100" } ?? "--/100")
                .font(DesignSystem.Font.footnote)
                .foregroundColor(DesignSystem.Color.textPrimary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(DesignSystem.Color.primary)
        )
        .overlay(
            Capsule().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
        )
    }

    private func heartGaugePill(now: Date) -> some View {
        let value = latestRecord.map {
            Happiness.calculate(
                score: $0.score,
                capturedAt: $0.capturedAt,
                now: now
            )
        } ?? Happiness.defaultWhenNoRecord
        let clamped = min(max(Double(value) / 100.0, 0), 1)
        let barWidth: CGFloat = 110

        return HStack(spacing: 8) {
            ZStack {
                PixelHeartShape().fill(DesignSystem.Color.secondary)
                PixelHeartStrokeShape().fill(DesignSystem.Color.secondaryDark)
            }
            .frame(width: 22, height: 18)

            ZStack(alignment: .leading) {
                Capsule().fill(DesignSystem.Color.primary.opacity(0.5))
                Capsule()
                    .fill(DesignSystem.Color.secondary)
                    .frame(width: barWidth * clamped)
            }
            .frame(width: barWidth, height: 14)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(DesignSystem.Color.surface)
        )
        .overlay(
            Capsule().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
        )
    }

    // MARK: - Room Frame
    private func roomFrame(now: Date) -> some View {
        ZStack {
            DesignSystem.Color.secondary.opacity(0.15)

            if let data = latestRecord?.pixelArtImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fill)
            }

            if isRunaway {
                Image("okitegami")
                    .resizable()
                    .scaledToFit()
                    .padding(40)
            } else {
                VStack {
                    Spacer()
                    CharacterView(
                        characterType: selectedCharacterType,
                        characterState: characterState(at: now)
                    )
                    .frame(width: 200, height: 200)
                    .padding(.bottom, -30)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Color.primary, lineWidth: 5)
        )
        .overlay(alignment: .topTrailing) {
            heartGaugePill(now: now)
                .padding(.top, 12)
                .padding(.trailing, 12)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Mission Banner
    private var missionBanner: some View {
        Button(action: {
            isMissionSheetPresented = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignSystem.Color.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    PixelStar(size: 22)
                }
                Text(missionBannerText)
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .pixelSquareCard(
                fill: DesignSystem.Color.surface,
                border: DesignSystem.Color.primary,
                borderWidth: 2,
                shadowOffset: 3
            )
            .padding(.horizontal)
        }
    }

    private var missionBannerText: String {
        let count = pendingMissionCount
        if count > 0 {
            return "ミッションが\(count)件残っています"
        }
        return "撮影してお部屋を分析しよう！"
    }

    // MARK: - Camera Button
    private var cameraButton: some View {
        Button(action: {
            if canCapture {
                navigationRouter.navigate(to: .capture)
            } else {
                showCaptureAlert = true
            }
        }) {
            Image(systemName: "camera.fill")
                .font(DesignSystem.Font.title)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .frame(width: 72, height: 72)
                .background(
                    PixelCircle(pixelSize: 5)
                        .fill(canCapture ? DesignSystem.Color.primary : Color.gray)
                )
                .overlay(
                    PixelCircleStroke(pixelSize: 5, lineWidth: 4)
                        .fill(canCapture ? DesignSystem.Color.primaryDark : Color.gray.opacity(0.7))
                )
        }
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
