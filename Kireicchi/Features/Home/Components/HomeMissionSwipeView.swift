import SwiftUI

private enum MissionDecision {
    case later
    case complete
}

struct HomeMissionSwipeView: View {
    let missions: [MissionPersisted]
    let originalImage: UIImage?
    let onComplete: (MissionPersisted) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var topIndex: Int = 0
    @State private var dragOffset: CGSize = .zero
    @State private var exitingId: String?
    @State private var exitOffset: CGSize = .zero

    private let swipeThreshold: CGFloat = 100
    private let maxBackCards = 2
    private static let completeColor = SwiftUI.Color(hex: "1ABA7F")

    private var remaining: Int { max(0, missions.count - topIndex) }

    var body: some View {
        ZStack {
            DesignSystem.Color.primaryDark.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 16)
                cardStack
                Spacer(minLength: 16)
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("残り \(remaining)件")
                .font(DesignSystem.Font.headline)
                .foregroundColor(.white)
            Spacer()
            Spacer().frame(width: 44)
        }
        .padding(.top, 8)
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(visibleMissions().reversed(), id: \.offset) { pair in
                    let depth = pair.offset - topIndex
                    let mission = pair.element
                    let isTop = depth == 0
                    let isExiting = exitingId == mission.id

                    HomeMissionCard(
                        mission: mission,
                        originalImage: originalImage,
                        dragOffset: isTop ? dragOffset : .zero,
                        isTop: isTop
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(isTop ? 1.0 : 1.0 - 0.04 * CGFloat(depth))
                    .offset(y: isTop ? 0 : CGFloat(depth) * 10)
                    .offset(isExiting ? exitOffset : (isTop ? dragOffset : .zero))
                    .rotationEffect(.degrees(rotation(for: isTop ? dragOffset : (isExiting ? exitOffset : .zero))))
                    .zIndex(isTop ? 10 : Double(maxBackCards - depth))
                    .gesture(isTop && exitingId == nil ? dragGesture(for: mission) : nil)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dragOffset)
                    .animation(.easeOut(duration: 0.28), value: exitOffset)
                }
            }
        }
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
        .frame(maxHeight: 560)
    }

    private func visibleMissions() -> [(offset: Int, element: MissionPersisted)] {
        let upper = min(topIndex + maxBackCards + 1, missions.count)
        guard topIndex < upper else { return [] }
        return (topIndex..<upper).map { ($0, missions[$0]) }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 14) {
            Button(action: { tap(.later) }) {
                Text("後でやる")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(DesignSystem.Color.surface)
                    )
                    .overlay(
                        Capsule().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .disabled(remaining == 0)

            Button(action: { tap(.complete) }) {
                Text("完了")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(Self.completeColor)
                    )
                    .overlay(
                        Capsule().stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .disabled(remaining == 0)
        }
    }

    // MARK: - Gesture

    private func dragGesture(for mission: MissionPersisted) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if abs(value.translation.width) > swipeThreshold {
                    let decision: MissionDecision = value.translation.width > 0 ? .complete : .later
                    commit(mission: mission, decision: decision, from: value.translation)
                } else {
                    dragOffset = .zero
                }
            }
    }

    private func rotation(for offset: CGSize) -> Double {
        Double(offset.width) / 20.0
    }

    // MARK: - Action

    private func tap(_ decision: MissionDecision) {
        guard topIndex < missions.count else { return }
        let mission = missions[topIndex]
        let target: CGFloat = decision == .complete ? 700 : -700
        commit(mission: mission, decision: decision, from: CGSize(width: target, height: 0))
    }

    private func commit(mission: MissionPersisted, decision: MissionDecision, from translation: CGSize) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let targetX: CGFloat = decision == .complete ? 700 : -700
        exitingId = mission.id
        exitOffset = CGSize(width: targetX, height: translation.height)
        dragOffset = .zero

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if decision == .complete {
                onComplete(mission)
            }
            topIndex += 1
            exitingId = nil
            exitOffset = .zero

            if topIndex >= missions.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let img = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 900)).image { ctx in
        UIColor.systemBlue.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 900))
        UIColor.systemYellow.setFill()
        ctx.fill(CGRect(x: 100, y: 400, width: 300, height: 350))
    }
    return HomeMissionSwipeView(
        missions: [
            MissionPersisted(id: "床の上の服|3", label: "床の上の服を片付けよう", priority: 3,
                             bbox: NormalizedRect(x: 0.1, y: 0.5, w: 0.5, h: 0.4), isDone: false),
            MissionPersisted(id: "机の上の紙|2", label: "机の上の紙を整理しよう", priority: 2,
                             bbox: NormalizedRect(x: 0.3, y: 0.2, w: 0.4, h: 0.3), isDone: false),
            MissionPersisted(id: "カバン|1", label: "カバンを定位置に戻そう", priority: 1, bbox: nil, isDone: false)
        ],
        originalImage: img,
        onComplete: { mission in print("完了: \(mission.label)") }
    )
}
