import SwiftUI

enum SwipeDirection {
    case left, right
}

struct SwipeMissionStack: View {
    let missions: [MissionPersisted]
    let originalImage: UIImage?
    let onSwipe: (MissionPersisted, SwipeDirection) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var exitingId: String?
    @State private var exitOffset: CGSize = .zero

    private let swipeThreshold: CGFloat = 100
    private let maxBackCards = 2

    var body: some View {
        Group {
            if missions.isEmpty {
                emptyState
            } else {
                stack
            }
        }
    }

    private var stack: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(missions.prefix(maxBackCards + 1).enumerated()).reversed(), id: \.element.id) { pair in
                    let depth = pair.offset
                    let mission = pair.element
                    let isTop = depth == 0
                    let isExiting = exitingId == mission.id

                    SwipeMissionCard(
                        mission: mission,
                        originalImage: originalImage,
                        dragOffset: isTop ? dragOffset : .zero,
                        isTop: isTop
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(isTop ? 1.0 : 1.0 - 0.04 * CGFloat(depth))
                    .offset(y: isTop ? 0 : CGFloat(depth) * 8)
                    .offset(isExiting ? exitOffset : (isTop ? dragOffset : .zero))
                    .rotationEffect(.degrees(rotation(for: isTop ? dragOffset : (isExiting ? exitOffset : .zero))))
                    .zIndex(isTop ? 10 : Double(maxBackCards - depth))
                    .gesture(isTop && exitingId == nil ? dragGesture(for: mission) : nil)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dragOffset)
                    .animation(.easeOut(duration: 0.28), value: exitOffset)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            CharacterView(characterType: .character01, characterState: nil, forceGif: .cheer)
                .frame(width: 140, height: 140)
            Text("全部終わった！")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
            Text("お疲れさま✨")
                .font(DesignSystem.Font.subheadline)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rotation(for offset: CGSize) -> Double {
        Double(offset.width) / 20.0
    }

    private func dragGesture(for mission: MissionPersisted) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if abs(value.translation.width) > swipeThreshold {
                    let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
                    commitSwipe(mission: mission, direction: direction, from: value.translation)
                } else {
                    dragOffset = .zero
                }
            }
    }

    private func commitSwipe(mission: MissionPersisted, direction: SwipeDirection, from translation: CGSize) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let targetX: CGFloat = direction == .right ? 700 : -700
        exitingId = mission.id
        exitOffset = CGSize(width: targetX, height: translation.height)
        dragOffset = .zero

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onSwipe(mission, direction)
            exitingId = nil
            exitOffset = .zero
        }
    }
}

#Preview {
    let img = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600)).image { ctx in
        UIColor.systemBlue.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 600))
        UIColor.systemYellow.setFill()
        ctx.fill(CGRect(x: 100, y: 300, width: 300, height: 200))
    }
    return SwipeMissionStack(
        missions: [
            MissionPersisted(id: "床の上の服|3", label: "床の上の服", priority: 3,
                             bbox: NormalizedRect(x: 0.1, y: 0.5, w: 0.5, h: 0.4), isDone: false),
            MissionPersisted(id: "机の上の紙|2", label: "机の上の紙", priority: 2,
                             bbox: NormalizedRect(x: 0.3, y: 0.2, w: 0.4, h: 0.3), isDone: false),
            MissionPersisted(id: "カバン|1", label: "カバン", priority: 1, bbox: nil, isDone: false)
        ],
        originalImage: img,
        onSwipe: { mission, dir in print("\(mission.label) → \(dir)") }
    )
    .frame(height: 420)
    .padding(20)
    .background(DesignSystem.Color.background)
}
