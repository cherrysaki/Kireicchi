import SwiftUI

struct SwipeMissionCard: View {
    let mission: MissionPersisted
    let originalImage: UIImage?
    let dragOffset: CGSize
    let isTop: Bool

    @State private var croppedImage: UIImage?

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
        VStack(spacing: 0) {
            ZStack {
                Rectangle().fill(DesignSystem.Color.secondary.opacity(0.2))

                if let img = croppedImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }

                ZStack {
                    Rectangle()
                        .fill(DesignSystem.Color.primary)
                        .opacity(rightOverlayOpacity * 0.55)
                    Text("DONE")
                        .font(DesignSystem.Font.title)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(DesignSystem.Color.surface.opacity(0.85))
                        .overlay(Rectangle().stroke(DesignSystem.Color.primaryDark, lineWidth: 3))
                        .rotationEffect(.degrees(-12))
                        .opacity(rightOverlayOpacity)
                }

                ZStack {
                    Rectangle()
                        .fill(DesignSystem.Color.secondary)
                        .opacity(leftOverlayOpacity * 0.55)
                    Text("SKIP")
                        .font(DesignSystem.Font.title)
                        .foregroundColor(DesignSystem.Color.textPrimary)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(DesignSystem.Color.surface.opacity(0.85))
                        .overlay(Rectangle().stroke(DesignSystem.Color.primaryDark, lineWidth: 3))
                        .rotationEffect(.degrees(12))
                        .opacity(leftOverlayOpacity)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipped()

            VStack(spacing: 8) {
                Text(mission.label)
                    .font(DesignSystem.Font.headline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: 3) {
                    ForEach(0..<starCount, id: \.self) { _ in
                        PixelStar(size: 16)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.surface)
        }
        .background(DesignSystem.Color.surface)
        .clipShape(PixelCornerRectangle(cornerRadius: 10))
        .overlay(PixelCornerRectangle(cornerRadius: 10).stroke(DesignSystem.Color.primaryDark, lineWidth: 3))
        .background(
            PixelCornerRectangle(cornerRadius: 10)
                .fill(DesignSystem.Color.primaryDark.opacity(0.35))
                .offset(x: 5, y: 5)
        )
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
    let img = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400)).image { ctx in
        UIColor.systemTeal.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
        UIColor.systemPink.setFill()
        ctx.fill(CGRect(x: 40, y: 200, width: 200, height: 160))
    }
    return SwipeMissionCard(
        mission: mission,
        originalImage: img,
        dragOffset: .zero,
        isTop: true
    )
    .padding(40)
    .background(DesignSystem.Color.background)
}
