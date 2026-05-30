import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @EnvironmentObject var deps: AppDependencies
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
                historyBanner
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
        .onAppear { saveWidgetSnapshot() }
        .onChange(of: records.first?.capturedAt) { _, _ in saveWidgetSnapshot() }
        .alert("本日の撮影は終了しました", isPresented: $showCaptureAlert) {
            Button("OK") {}
        } message: {
            Text("1日2回まで撮影できます。\nまた明日撮影してね！")
        }
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
        let calendar = Calendar.current

        let hour = deps.currentUser?.notificationSettings.hour ?? 19
        let minute = deps.currentUser?.notificationSettings.minute ?? 0

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        let todayScheduled = calendar.date(from: components) ?? now

        let isPastScheduled = now >= todayScheduled

        let hasCapturedToday = historyRecords.contains {
            calendar.isDateInToday($0.capturedAt)
        }

        if isPastScheduled {
            if hasCapturedToday {
                return "また明日も撮影しようね！"
            } else {
                return "今すぐ撮影しよう！"
            }
        } else {
            if hasCapturedToday {
                let remaining = todayScheduled.timeIntervalSince(now)
                let hours = Int(remaining) / 3600
                let minutes = (Int(remaining) % 3600) / 60
                return "次の撮影まで \(hours)時間\(minutes)分"
            } else {
                let remaining = todayScheduled.timeIntervalSince(now)
                let hours = Int(remaining) / 3600
                let minutes = (Int(remaining) % 3600) / 60
                return "次の撮影まで \(hours)時間\(minutes)分"
            }
        }
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
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                DesignSystem.Color.secondary.opacity(0.15)

                if let data = latestRecord?.pixelArtImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                }

                if isRunaway {
                    Image("okitegami")
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                        .frame(width: geo.size.width, height: geo.size.width)
                } else {
                    VStack {
                        Spacer()
                        CharacterView(
                            characterType: selectedCharacterType,
                            characterState: characterState(at: now)
                        )
                        .frame(
                            width: geo.size.width * 0.5,
                            height: geo.size.width * 0.5
                        )
                        .padding(.bottom, 8)
                    }
                    .frame(width: geo.size.width, height: geo.size.width)
                }

                heartGaugePill(now: now)
                    .padding(10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(DesignSystem.Color.primary, lineWidth: 5)
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
                RoundedRectangle(cornerRadius: 14).fill(DesignSystem.Color.secondary.opacity(0.4))
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

    private func saveWidgetSnapshot() {
        let now = Date()
        if let record = latestRecord {
            let happiness = Happiness.calculate(score: record.score, capturedAt: record.capturedAt, now: now)
            let state = CharacterState.fromHappiness(happiness)
            let daysSince = Calendar.current.dateComponents([.day], from: record.capturedAt, to: now).day ?? 0
            let snapshot = KireicchiWidgetSnapshot(
                happiness: happiness,
                characterState: state.rawValue,
                latestPixelRoomImageData: record.pixelArtImageData,
                lastCapturedAt: record.capturedAt,
                isGone: daysSince >= 7,
                updatedAt: now
            )
            deps.widgetDataStore.save(snapshot: snapshot)
        } else {
            let snapshot = KireicchiWidgetSnapshot(
                happiness: Happiness.defaultWhenNoRecord,
                characterState: CharacterState.happy.rawValue,
                latestPixelRoomImageData: nil,
                lastCapturedAt: nil,
                isGone: false,
                updatedAt: now
            )
            deps.widgetDataStore.save(snapshot: snapshot)
        }
    }

    // MARK: - History Banner
    private var historyBanner: some View {
        Button(action: {
            navigationRouter.navigate(to: .history)
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
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16))
                        .foregroundColor(DesignSystem.Color.primaryDark)
                }
                Text("これまでの記録")
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
                RoundedRectangle(cornerRadius: 14)
                    .fill(DesignSystem.Color.secondary.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationRouter())
            .modelContainer(for: LatestRoomRecord.self, inMemory: true)
    }
}
