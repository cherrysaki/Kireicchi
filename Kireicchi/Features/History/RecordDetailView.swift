import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    let record: RoomHistoryRecord

    private var pixelArtImage: UIImage? {
        record.pixelArtImageData.flatMap { UIImage(data: $0) }
    }

    private var missions: [MissionPersisted] {
        record.missions.sorted { $0.priority > $1.priority }
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        summaryCard
                        pixelArtSection
                        if let comment = record.comment, !comment.isEmpty {
                            commentSection(comment)
                        }
                        missionSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button(action: { navigationRouter.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text("記録の詳細")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            Spacer().frame(width: 32)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.capturedAt.formatted(date: .long, time: .shortened))
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                Text("ランク \(record.rank)")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.primaryDark)
            }
            Spacer()
            VStack(spacing: 0) {
                Text("\(record.score)")
                    .font(DesignSystem.Font.title)
                    .foregroundColor(DesignSystem.Color.primaryDark)
                Text("点")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            PixelCornerRectangle(cornerRadius: 16).fill(DesignSystem.Color.surface)
        )
        .overlay(
            PixelCornerRectangle(cornerRadius: 16)
                .stroke(DesignSystem.Color.primary, lineWidth: 2)
        )
    }

    // MARK: - Pixel Art
    private var pixelArtSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ドット絵のお部屋")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let image = pixelArtImage {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(1, contentMode: .fit)
                } else {
                    PixelCornerRectangle(cornerRadius: 12)
                        .fill(DesignSystem.Color.secondary.opacity(0.25))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Text("画像なし")
                                .font(DesignSystem.Font.subheadline)
                                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                        )
                }
            }
            .background(DesignSystem.Color.secondary.opacity(0.2))
            .clipShape(PixelCornerRectangle(cornerRadius: 12))
            .overlay(
                PixelCornerRectangle(cornerRadius: 12)
                    .stroke(DesignSystem.Color.primary, lineWidth: 5)
            )
        }
    }

    // MARK: - Comment
    private func commentSection(_ comment: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            CharacterView(characterType: .character01, characterState: nil, forceGif: .cheer)
                .frame(width: 64, height: 64)

            Text(comment)
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .pixelSquareCard(
                    fill: DesignSystem.Color.secondary.opacity(0.4),
                    border: DesignSystem.Color.primary,
                    borderWidth: 2,
                    shadowOffset: 3
                )
        }
        .padding(.trailing, 3)
    }

    // MARK: - Missions
    private var missionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("片付けミッション")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if missions.isEmpty {
                Text("ミッションの記録はありません")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(missions, id: \.id) { mission in
                        RecordMissionRow(mission: mission)
                    }
                }
                .padding(.trailing, 3)
            }
        }
    }
}

private struct RecordMissionRow: View {
    let mission: MissionPersisted

    private var starCount: Int { min(max(mission.priority, 1), 5) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mission.isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(mission.isDone ? DesignSystem.Color.secondaryDark : DesignSystem.Color.primary)

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
    let record = RoomHistoryRecord(
        capturedAt: Date(),
        score: 72,
        rank: "B",
        pixelArtImageData: nil,
        comment: "だいぶ片付いてきたね！この調子✨",
        missions: [
            MissionPersisted(id: "床の上の服|3", label: "床の上の服", priority: 3, bbox: nil, isDone: false),
            MissionPersisted(id: "机の上の紙|2", label: "机の上の紙", priority: 2, bbox: nil, isDone: false)
        ]
    )
    NavigationStack {
        RecordDetailView(record: record)
            .environmentObject(NavigationRouter())
    }
}
