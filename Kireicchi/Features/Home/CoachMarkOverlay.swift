import SwiftUI

// MARK: - Anchor PreferenceKeys
// anchorPreference 方式: ボタンの .bounds アンカーを吸い上げ、overlayPreferenceValue 内の
// GeometryReader で geo[anchor] として解決することで座標空間のずれを根本的に解消する。
// カメラボタンは別ファイル（HomeTabBar）から設定するため internal。

struct CoachAnchors: Equatable {
    var settings: Anchor<CGRect>?
    var camera: Anchor<CGRect>?
}

struct CoachAnchorKey: PreferenceKey {
    static var defaultValue = CoachAnchors()
    static func reduce(value: inout CoachAnchors, nextValue: () -> CoachAnchors) {
        let next = nextValue()
        value.settings = value.settings ?? next.settings
        value.camera = value.camera ?? next.camera
    }
}

struct TimerSettingAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

// MARK: - Coach Bubble

struct CoachBubble: View {
    let text: String
    var arrowDirection: ArrowDirection = .down

    enum ArrowDirection {
        case up, down
    }

    var body: some View {
        VStack(spacing: 0) {
            if arrowDirection == .up {
                triangle
                    .rotationEffect(.degrees(180))
            }

            Text(text)
                .font(DesignSystem.Font.body)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(DesignSystem.Color.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DesignSystem.Color.primary, lineWidth: 2)
                        )
                )

            if arrowDirection == .down {
                triangle
            }
        }
        .allowsHitTesting(false)
    }

    private var triangle: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 10))
            path.addLine(to: CGPoint(x: 20, y: 0))
            path.closeSubpath()
        }
        .fill(DesignSystem.Color.background)
        .frame(width: 20, height: 10)
    }
}

// MARK: - Reversed Mask

extension View {
    func reversedMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask(
            Rectangle()
                .ignoresSafeArea()
                .overlay(
                    mask()
                        .blendMode(.destinationOut)
                )
        )
    }
}

// MARK: - Previews

#Preview("CoachBubble") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        VStack(spacing: 60) {
            CoachBubble(text: "まずはここから\n撮影する時間を決めよう！", arrowDirection: .up)
            CoachBubble(text: "つぎはお部屋を\n撮影してみよう！", arrowDirection: .down)
        }
    }
}
