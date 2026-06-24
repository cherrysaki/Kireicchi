import SwiftUI

// MARK: - Button Frame PreferenceKeys
// HomeView（設定ボタン）と HomeTabBar（カメラボタン）から座標を吸い上げるため internal。

struct SettingsButtonFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct CameraButtonFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct TimerSettingFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Coach Mark Overlay

struct CoachMarkOverlay: View {
    let currentStep: Int
    let highlightFrame: CGRect

    var body: some View {
        ZStack {
            // 半透明オーバーレイ（ハイライト部分を切り抜き）
            Color.black.opacity(0.5)
                .reversedMask {
                    RoundedRectangle(cornerRadius: 12)
                        .frame(
                            width: highlightFrame.width + 20,
                            height: highlightFrame.height + 20
                        )
                        .position(
                            x: highlightFrame.midX,
                            y: highlightFrame.midY
                        )
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                // ↑ オーバーレイはタップを透過（ハイライト部分のボタンを実際に押せるように）

            // 吹き出し
            coachBubble
        }
    }

    @ViewBuilder
    private var coachBubble: some View {
        switch currentStep {
        case 0:
            CoachBubble(
                text: "まずはここから\n撮影する時間を決めよう！",
                arrowDirection: .up
            )
            .position(
                x: highlightFrame.midX,
                y: highlightFrame.maxY + 80
            )
        case 1:
            CoachBubble(
                text: "つぎはお部屋を\n撮影してみよう！",
                arrowDirection: .down
            )
            .position(
                x: highlightFrame.midX,
                y: highlightFrame.minY - 80
            )
        default:
            EmptyView()
        }
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

#Preview("Step 0: 設定ボタン") {
    ZStack {
        DesignSystem.Color.background.ignoresSafeArea()
        CoachMarkOverlay(
            currentStep: 0,
            highlightFrame: CGRect(x: 30, y: 80, width: 44, height: 44)
        )
    }
}

#Preview("Step 1: 撮影ボタン") {
    ZStack {
        DesignSystem.Color.background.ignoresSafeArea()
        CoachMarkOverlay(
            currentStep: 1,
            highlightFrame: CGRect(x: 175, y: 720, width: 64, height: 64)
        )
    }
}

#Preview("CoachBubble") {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        VStack(spacing: 60) {
            CoachBubble(text: "まずはここから\n撮影する時間を決めよう！", arrowDirection: .up)
            CoachBubble(text: "つぎはお部屋を\n撮影してみよう！", arrowDirection: .down)
        }
    }
}
