import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Query private var records: [LatestRoomRecord]

    @AppStorage("selectedCharacterID") private var selectedCharacterTypeRaw: String = CharacterType.character01.rawValue

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

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 16) {
                topBar
                scoreBanner
                happinessGauge
                roomFrame
                if isRunaway {
                    runawayMessage
                } else {
                    missionList
                }
                Spacer(minLength: 8)
                cameraButton
                    .padding(.bottom, 16)
                Spacer().frame(height: 24)
            }
            .padding(.top, 8)
            .background(DesignSystem.Color.background.ignoresSafeArea())
        }
        .background(DesignSystem.Color.background.ignoresSafeArea())
        .navigationBarHidden(true)
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

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                navigationRouter.navigate(to: .settings)
            }) {
                Image(systemName: "gearshape.fill")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        PixelCircle(pixelSize: 3)
                            .fill(DesignSystem.Color.surface)
                    )
                    .overlay(
                        PixelCircleStroke(pixelSize: 3, lineWidth: 3)
                            .fill(DesignSystem.Color.primary)
                    )
            }

            Spacer()

            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(nextCaptureText(capturedAt: latestRecord?.capturedAt, now: context.date))
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Score Banner
    private var scoreBanner: some View {
        HStack {
            Text("お部屋の散らかり指数")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Spacer()
            Text(latestRecord.map { "\($0.score)/100" } ?? "--/100")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.primaryDark)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .pixelSquareCard(
            fill: DesignSystem.Color.secondary.opacity(0.45),
            border: DesignSystem.Color.primary,
            borderWidth: 3,
            shadowOffset: 4
        )
        .padding(.horizontal)
        .padding(.trailing, 4)
    }

    // MARK: - Happiness Gauge
    private var happinessGauge: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let value = latestRecord.map {
                Happiness.calculate(
                    score: $0.score,
                    capturedAt: $0.capturedAt,
                    now: context.date
                )
            } ?? Happiness.defaultWhenNoRecord
            PixelHeartGauge(value: value)
                .padding(.horizontal)
        }
    }

    // MARK: - Room Frame
    private var roomFrame: some View {
        ZStack {
            Rectangle()
                .fill(DesignSystem.Color.secondary.opacity(0.25))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Rectangle()
                        .stroke(DesignSystem.Color.primary, lineWidth: 3)
                )

            if let data = latestRecord?.pixelArtImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
            }

            if isRunaway {
                Image("okitegami")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 360, height: 360)
            } else {
                VStack {
                    Spacer()

                    VStack(spacing: 4) {
                        CharacterView(
                            characterType: selectedCharacterType,
                            characterState: characterState
                        )
                        .frame(width: 240, height: 240)
                    }
                    .padding(.bottom, -60)
                }
            }
        }
        .padding(.horizontal)
        .padding(.trailing, 4)
    }

    // MARK: - Mission List
    private var missionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                PixelStar(size: 22)
                Text("お片付けミッション")
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }
            .padding(.horizontal)

            if let record = latestRecord,
               let messyPointLabels = record.messyPointLabels,
               !messyPointLabels.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(messyPointLabels.prefix(3).enumerated()), id: \.offset) { index, label in
                        CleanupTaskRow(label: label, index: index)
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
            } else {
                Text("撮影してお部屋を分析しよう！")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Runaway Message
    private var runawayMessage: some View {
        VStack(spacing: 4) {
            Text("きれいっちは家出しました")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)
        }
        .padding(.horizontal)
    }

    // MARK: - Camera Button
    private var cameraButton: some View {
        Button(action: {
            navigationRouter.navigate(to: .capture)
        }) {
            Image(systemName: "camera.fill")
                .font(DesignSystem.Font.title)
                .foregroundColor(DesignSystem.Color.textOnPrimary)
                .frame(width: 72, height: 72)
                .background(
                    PixelCircle(pixelSize: 5)
                        .fill(DesignSystem.Color.primary)
                )
                .overlay(
                    PixelCircleStroke(pixelSize: 5, lineWidth: 4)
                        .fill(DesignSystem.Color.primaryDark)
                )
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
