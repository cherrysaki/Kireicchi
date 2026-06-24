import SwiftUI

struct WorldviewOnboardingView: View {
    @AppStorage("hasShownWorldviewOnboarding") private var hasShownWorldviewOnboarding: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                morningSection
                sectionDivider
                eggSection
                sectionDivider
                stateSection
                sectionDivider
                welcomeSection
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 48)
        }
        .background(DesignSystem.Color.background.ignoresSafeArea())
    }

    // MARK: - Section 1: 朝の部屋

    private var morningSection: some View {
        VStack(spacing: 24) {
            MorningRoomIllustration()
                .frame(width: 240, height: 240)

            VStack(spacing: 12) {
                Text("ある朝、ふしぎな出来事がありました。")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text("目を覚ますと、窓辺に見なれない卵が置かれていました。")
                    .font(DesignSystem.Font.body)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Section 2: 卵のアップ

    private var eggSection: some View {
        VStack(spacing: 24) {
            EggIllustration()
                .frame(width: 220, height: 220)

            VStack(spacing: 12) {
                Text("その卵は、きれいっちの卵でした。")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text("きれいっちは、お部屋を見守る小さな妖精です。")
                    .font(DesignSystem.Font.body)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Section 3: きれいっちの説明

    private var stateSection: some View {
        VStack(spacing: 24) {
            CharacterStateCards()

            VStack(spacing: 12) {
                Text("きれいっちは、お部屋と一緒に暮らします。")
                    .font(DesignSystem.Font.title3)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Text("お部屋が片付くと、きれいっちは元気になります。")
                    Text("お部屋が散らかると、少し元気がなくなります。")
                    Text("そして、長い間ひとりぼっちにすると、どこかへ行ってしまうこともあります。")
                }
                .font(DesignSystem.Font.body)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
                .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Section 4: お迎えボタン

    private var welcomeSection: some View {
        VStack(spacing: 24) {
            HappyCharacterIllustration()
                .frame(width: 220, height: 220)

            Text("きれいっちと一緒に、心地よいお部屋をつくりませんか？")
                .font(DesignSystem.Font.title3)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            Button {
                hasShownWorldviewOnboarding = true
            } label: {
                Text("きれいっちの卵を迎える")
                    .font(DesignSystem.Font.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(PixelButtonStyle())
            .padding(.top, 8)

            Text("きれいっちお迎え窓口")
                .font(DesignSystem.Font.custom(size: 12))
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.4))
                .padding(.top, 4)
        }
    }

    // MARK: - Divider

    private var sectionDivider: some View {
        Rectangle()
            .fill(DesignSystem.Color.textPrimary.opacity(0.15))
            .frame(width: 200, height: 1)
            .padding(.vertical, 32)
    }
}

// MARK: - Sparkle Shape (4点のキラキラ)

private struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let dx = rect.width * 0.14
        let dy = rect.height * 0.14
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: cy), control: CGPoint(x: cx + dx, y: cy - dy))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.maxY), control: CGPoint(x: cx + dx, y: cy + dy))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: cy), control: CGPoint(x: cx - dx, y: cy + dy))
        path.addQuadCurve(to: CGPoint(x: cx, y: rect.minY), control: CGPoint(x: cx - dx, y: cy - dy))
        path.closeSubpath()
        return path
    }
}

private struct Sparkle: View {
    var size: CGFloat = 16
    var opacity: Double = 1.0

    var body: some View {
        SparkleShape()
            .fill(DesignSystem.Color.accent.opacity(opacity))
            .frame(width: size, height: size)
    }
}

// MARK: - Section 1 イラスト: 朝の部屋

private struct MorningRoomIllustration: View {
    var body: some View {
        ZStack {
            // 棚（部屋の暗示）
            RoundedRectangle(cornerRadius: 3)
                .fill(DesignSystem.Color.primaryDark.opacity(0.12))
                .frame(width: 70, height: 8)
                .offset(x: -78, y: 70)

            // 植物
            plant
                .offset(x: -78, y: 44)

            // 窓
            window

            // 窓辺の卵
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [DesignSystem.Color.surface, DesignSystem.Color.accent.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Ellipse().stroke(DesignSystem.Color.primaryDark.opacity(0.4), lineWidth: 2))
                .frame(width: 56, height: 72)
                .offset(y: 56)

            // 窓辺（台）
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.Color.primaryDark.opacity(0.18))
                .frame(width: 200, height: 10)
                .offset(y: 96)

            // 卵まわりのキラキラ
            Sparkle(size: 18).offset(x: 44, y: 36)
            Sparkle(size: 12, opacity: 0.8).offset(x: -42, y: 50)
            Sparkle(size: 10, opacity: 0.7).offset(x: 36, y: 84)
        }
    }

    private var window: some View {
        ZStack {
            // 空（朝日のグラデーション）
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.Color.accent.opacity(0.9),
                            DesignSystem.Color.accentWarm.opacity(0.5),
                            DesignSystem.Color.primary.opacity(0.4)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 150, height: 170)

            // 朝日
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DesignSystem.Color.surface, DesignSystem.Color.accent],
                        center: .center,
                        startRadius: 2,
                        endRadius: 30
                    )
                )
                .frame(width: 50, height: 50)
                .offset(x: 28, y: -30)

            // 窓枠の十字
            Rectangle()
                .fill(DesignSystem.Color.surface)
                .frame(width: 150, height: 6)
            Rectangle()
                .fill(DesignSystem.Color.surface)
                .frame(width: 6, height: 170)

            // 窓枠
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.Color.primaryDark.opacity(0.55), lineWidth: 6)
                .frame(width: 150, height: 170)
        }
        .offset(y: -10)
    }

    private var plant: some View {
        ZStack {
            // 鉢
            Trapezoid()
                .fill(DesignSystem.Color.accentWarm.opacity(0.5))
                .frame(width: 22, height: 16)
                .offset(y: 14)
            // 葉
            Ellipse()
                .fill(DesignSystem.Color.primary.opacity(0.6))
                .frame(width: 12, height: 22)
                .rotationEffect(.degrees(-22))
                .offset(x: -5)
            Ellipse()
                .fill(DesignSystem.Color.primary.opacity(0.7))
                .frame(width: 12, height: 22)
                .rotationEffect(.degrees(22))
                .offset(x: 5)
        }
    }
}

private struct Trapezoid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.18
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Section 2 イラスト: 卵のアップ

private struct EggIllustration: View {
    var body: some View {
        ZStack {
            // 背後の光の輪
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DesignSystem.Color.accent.opacity(0.4), DesignSystem.Color.accent.opacity(0)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)

            Circle()
                .stroke(DesignSystem.Color.accent.opacity(0.3), lineWidth: 2)
                .frame(width: 150, height: 150)

            // 大きな卵
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [DesignSystem.Color.surface, DesignSystem.Color.accent.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(Ellipse().stroke(DesignSystem.Color.primaryDark.opacity(0.4), lineWidth: 3))
                .frame(width: 110, height: 140)

            // 卵のハイライト
            Ellipse()
                .fill(DesignSystem.Color.surface.opacity(0.8))
                .frame(width: 22, height: 34)
                .offset(x: -22, y: -34)

            // 周囲のキラキラ
            Sparkle(size: 22).offset(x: 70, y: -56)
            Sparkle(size: 14, opacity: 0.8).offset(x: -72, y: -36)
            Sparkle(size: 18, opacity: 0.9).offset(x: 78, y: 44)
            Sparkle(size: 12, opacity: 0.7).offset(x: -66, y: 60)
            Sparkle(size: 10, opacity: 0.7).offset(x: 0, y: -92)
        }
    }
}

// MARK: - Section 3 イラスト: 状態カード

private struct CharacterStateCards: View {
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                stateCard(
                    label: "げんき！",
                    background: SwiftUI.Color.green.opacity(0.1),
                    border: SwiftUI.Color.green.opacity(0.3)
                ) {
                    CharacterView(characterType: .character01, characterState: .happy)
                        .frame(width: 64, height: 64)
                }

                stateCard(
                    label: "しょんぼり…",
                    background: SwiftUI.Color.orange.opacity(0.1),
                    border: SwiftUI.Color.orange.opacity(0.3)
                ) {
                    CharacterView(characterType: .character01, characterState: .sad)
                        .frame(width: 64, height: 64)
                }
            }

            stateCard(
                label: "どこかへ いっちゃう…",
                background: DesignSystem.Color.textPrimary.opacity(0.05),
                border: DesignSystem.Color.textPrimary.opacity(0.1)
            ) {
                ZStack {
                    Circle()
                        .stroke(
                            DesignSystem.Color.textPrimary.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                        )
                        .frame(width: 60, height: 60)
                    Text("？")
                        .font(DesignSystem.Font.title2)
                        .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.4))
                }
                .frame(width: 64, height: 64)
            }
            .frame(maxWidth: 180)
        }
    }

    private func stateCard<Content: View>(
        label: String,
        background: SwiftUI.Color,
        border: SwiftUI.Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 10) {
            content()
            Text(label)
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                .fill(background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Layout.cardCornerRadius)
                .stroke(border, lineWidth: 2)
        )
    }
}

// MARK: - Section 4 イラスト: 元気なきれいっち

private struct HappyCharacterIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [DesignSystem.Color.accent.opacity(0.35), DesignSystem.Color.accent.opacity(0)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)

            CharacterView(characterType: .character01, characterState: .happy)
                .frame(width: 130, height: 130)

            Sparkle(size: 22).offset(x: 74, y: -52)
            Sparkle(size: 14, opacity: 0.8).offset(x: -78, y: -30)
            Sparkle(size: 18, opacity: 0.9).offset(x: 80, y: 50)
            Sparkle(size: 12, opacity: 0.7).offset(x: -70, y: 56)
        }
    }
}

#Preview {
    WorldviewOnboardingView()
}
