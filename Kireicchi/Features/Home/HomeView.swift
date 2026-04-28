import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @Query private var records: [LatestRoomRecord]
    @StateObject private var appDependencies = AppDependencies.shared

    @AppStorage("selectedCharacterID") private var selectedCharacterTypeRaw: String = CharacterType.character01.rawValue

    private var latestRecord: LatestRoomRecord? { records.first }

    private var selectedCharacterType: CharacterType {
        CharacterType(rawValue: selectedCharacterTypeRaw) ?? .character01
    }

    private var characterState: CharacterState {
        guard let score = latestRecord?.score else { return .happy }
        return CharacterState.fromScore(score)
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 16) {
                topBar
                scoreBanner
                happinessGauge
                roomFrame
                missionList
                Spacer(minLength: 8)
                cameraButton
                debugFooter
            }
            .padding(.top, 8)
        }
        .navigationBarHidden(true)
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

            Text("つぎのさつえいまで: 8じかん30ぷん")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))

            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Score Banner
    private var scoreBanner: some View {
        HStack {
            Text("おへやの ちらかりしすう")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
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
        VStack(alignment: .leading, spacing: 6) {
            Text("ハッピーど")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))

            HStack(spacing: 4) {
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(index < 5 ? DesignSystem.Color.primary : DesignSystem.Color.secondary.opacity(0.3))
                        .frame(height: 12)
                }
            }
            .padding(.horizontal, 4)
            .overlay(
                Rectangle()
                    .stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
            )
        }
        .padding(.horizontal)
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

            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("もう すこし\nかたづけよう！")
                            .font(DesignSystem.Font.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(DesignSystem.Color.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .pixelSquareCard(
                                fill: DesignSystem.Color.surface,
                                border: DesignSystem.Color.primaryDark,
                                borderWidth: 2,
                                shadowOffset: 2
                            )

                        CharacterView(
                            characterType: selectedCharacterType,
                            characterState: characterState
                        )
                        .frame(width: 130, height: 130)
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 16)

                Spacer()

                if latestRecord == nil {
                    Text("🏠")
                        .font(DesignSystem.Font.custom(size: 56))
                }

                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.trailing, 4)
    }

    // MARK: - Mission List
    private var missionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("⭐")
                    .font(DesignSystem.Font.subheadline)
                Text("おかたづけミッション")
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
            }
            .padding(.horizontal)

            if let record = latestRecord, !record.messyPointLabels.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(record.messyPointLabels.prefix(3).enumerated()), id: \.offset) { index, label in
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
                Text("さつえいして おへやを ぶんせきしよう！")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Camera Button
    private var cameraButton: some View {
        HStack(spacing: 16) {
            Button(action: {
                navigationRouter.navigate(to: .friendVisit)
            }) {
                Image(systemName: "person.2.fill")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.textOnPrimary)
                    .frame(width: 56, height: 56)
                    .background(
                        PixelCircle(pixelSize: 4)
                            .fill(DesignSystem.Color.secondary)
                    )
                    .overlay(
                        PixelCircleStroke(pixelSize: 4, lineWidth: 3)
                            .fill(DesignSystem.Color.primaryDark)
                    )
            }

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

    // MARK: - Debug Footer
    @ViewBuilder
    private var debugFooter: some View {
        #if DEBUG
        VStack(spacing: 6) {
            Text(appDependencies.useMockAPI ? "Mock しようちゅう" : "Real API しようちゅう")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.5))

            Button(action: {
                appDependencies.toggleMockAPI()
            }) {
                Text(appDependencies.useMockAPI ? "Real API に きりかえ" : "Mock に きりかえ")
                    .font(DesignSystem.Font.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .pixelSquareCard(
                        fill: DesignSystem.Color.surface,
                        border: DesignSystem.Color.textPrimary.opacity(0.3),
                        borderWidth: 2,
                        shadowOffset: 2
                    )
            }
        }
        .padding(.bottom, 24)
        #else
        Spacer().frame(height: 24)
        #endif
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(NavigationRouter())
            .modelContainer(for: LatestRoomRecord.self, inMemory: true)
    }
}
