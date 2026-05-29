import SwiftUI

struct HomeMissionCard: View {
    let mission: MissionPersisted
    let originalImage: UIImage?
    let dragOffset: CGSize
    let isTop: Bool

    @State private var croppedImage: UIImage?

    private static let completeColor = SwiftUI.Color(hex: "1ABA7F")

    private var starCount: Int { min(max(mission.priority, 1), 5) }

    private var rightOverlayOpacity: Double {
        guard isTop, dragOffset.width > 0 else { return 0 }
        return min(Double(dragOffset.width) / 120.0, 1.0)
    }

    private var leftOverlayOpacity: Double {
        guard isTop, dragOffset.width < 0 else { return 0 }
        return min(Double(-dragOffset.width) / 120.0, 1.0)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景画像 (なければプレースホルダ)
            ZStack {
                DesignSystem.Color.secondary.opacity(0.2)
                if let img = croppedImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }

            // 下半分グラデーション + ラベル
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 3) {
                    ForEach(0..<starCount, id: \.self) { _ in
                        PixelStar(size: 16)
                    }
                }
                Text(mission.label)
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding(20)

            // 右スワイプ → 緑 + 完了
            ZStack {
                Self.completeColor.opacity(rightOverlayOpacity * 0.7)
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                    Text("完了")
                        .font(DesignSystem.Font.title)
                        .foregroundColor(.white)
                }
                .opacity(rightOverlayOpacity)
            }

            // 左スワイプ → スカイ + 後でやる
            ZStack {
                DesignSystem.Color.primary.opacity(leftOverlayOpacity * 0.85)
                VStack(spacing: 12) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                    Text("後でやる")
                        .font(DesignSystem.Font.title)
                        .foregroundColor(.white)
                }
                .opacity(leftOverlayOpacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(DesignSystem.Color.primaryDark.opacity(0.4), lineWidth: 2)
        )
        .shadow(color: DesignSystem.Color.primaryDark.opacity(0.35), radius: 12, x: 4, y: 8)
        .task(id: mission.id) {
            croppedImage = originalImage?.cropped(normalized: mission.bbox)
        }
    }
}

#Preview {
    let mission = MissionPersisted(
        id: "床の上の服|3",
        label: "床の上の服",
        priority: 3,
        bbox: NormalizedRect(x: 0.1, y: 0.5, w: 0.5, h: 0.4),
        isDone: false
    )
    let img = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 900)).image { ctx in
        UIColor.systemTeal.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 900))
        UIColor.systemPink.setFill()
        ctx.fill(CGRect(x: 80, y: 500, width: 360, height: 320))
    }
    return HomeMissionCard(
        mission: mission,
        originalImage: img,
        dragOffset: .zero,
        isTop: true
    )
    .frame(width: 320, height: 480)
    .padding(40)
    .background(Color.black.opacity(0.5))
}
