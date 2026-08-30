import SwiftUI

struct PostcardDetailView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    let record: PostcardRecord

    private var pixelArtImage: UIImage? {
        UIImage(data: record.imageData)
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: { navigationRouter.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text("ポストカード")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Spacer()
            Spacer().frame(width: 32)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.fromUsername) さんから")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Text(record.sentAt.formatted(date: .long, time: .shortened))
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

    private var pixelArtSection: some View {
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

#Preview {
    NavigationStack {
        PostcardDetailView(record: PostcardRecord(
            id: "1", fromUid: "u1", fromUsername: "ぽろこ", score: 88, rank: "A", imageData: Data(), sentAt: Date()
        ))
        .environmentObject(NavigationRouter())
    }
}
