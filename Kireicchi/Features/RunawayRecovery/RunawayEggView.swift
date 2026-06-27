import SwiftUI

/// 家出復帰フロー: 卵画面 → 孵化 → 誕生
struct RunawayEggView: View {
    @Binding var isPresented: Bool
    @AppStorage("selectedCharacterID") private var selectedCharacterTypeRaw: String = CharacterType.character01.rawValue
    @AppStorage("isInRunawayState") private var isInRunawayState: Bool = false

    @State private var tapCount = 0
    @State private var phase: EggPhase = .waiting

    /// 卵の段階
    private enum EggPhase {
        case waiting     // タップ待ち
        case hatching    // 孵化演出中
        case born        // 誕生完了
    }

    private var selectedCharacterType: CharacterType {
        CharacterType(rawValue: selectedCharacterTypeRaw) ?? .character01
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            switch phase {
            case .waiting:
                eggContent
            case .hatching:
                hatchingContent
            case .born:
                birthContent
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Egg Content (tapping phase)

    private var eggContent: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("卵を3回タップしよう")
                .font(DesignSystem.Font.headline)
                .foregroundColor(DesignSystem.Color.textPrimary)

            // タップ進捗表示
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < tapCount
                              ? DesignSystem.Color.secondary
                              : DesignSystem.Color.primaryDark.opacity(0.2))
                        .frame(width: 14, height: 14)
                }
            }

            eggImage
                .onTapGesture {
                    handleTap()
                }

            Spacer()
        }
    }

    @State private var eggRotation: Double = 0
    @State private var eggScale: CGFloat = 1.0
    @State private var crackOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    private var eggImage: some View {
        ZStack {
            // 光のエフェクト
            Circle()
                .fill(DesignSystem.Color.accent.opacity(0.6))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .opacity(glowOpacity)

            Image("egg_dod")
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .rotationEffect(.degrees(eggRotation))
                .scaleEffect(eggScale)

            // ひび割れ表現
            if tapCount >= 2 {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 30))
                    .foregroundColor(DesignSystem.Color.accent)
                    .opacity(crackOpacity)
                    .offset(x: 20, y: -10)
            }
        }
    }

    private func handleTap() {
        guard tapCount < 3 else { return }
        tapCount += 1

        switch tapCount {
        case 1:
            // 1回目: 少し揺れる
            withAnimation(.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)) {
                eggRotation = 5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { eggRotation = 0 }
            }

        case 2:
            // 2回目: さらに揺れる・光る・ひびが入る
            withAnimation(.easeInOut(duration: 0.08).repeatCount(9, autoreverses: true)) {
                eggRotation = 10
            }
            withAnimation(.easeIn(duration: 0.3)) {
                glowOpacity = 0.5
                crackOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation {
                    eggRotation = 0
                    glowOpacity = 0.2
                }
            }

        case 3:
            // 3回目: 光ってきれいっちが誕生
            withAnimation(.easeInOut(duration: 0.05).repeatCount(15, autoreverses: true)) {
                eggRotation = 15
            }
            withAnimation(.easeIn(duration: 0.5)) {
                glowOpacity = 1.0
                eggScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    phase = .hatching
                }
            }

        default:
            break
        }
    }

    // MARK: - Hatching Content (transition)

    @State private var hatchFlashOpacity: Double = 1.0

    private var hatchingContent: some View {
        ZStack {
            // フラッシュ演出
            SwiftUI.Color.white
                .ignoresSafeArea()
                .opacity(hatchFlashOpacity)
        }
        .onAppear {
            // フラッシュ → 誕生画面へ
            withAnimation(.easeOut(duration: 0.6)) {
                hatchFlashOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.5)) {
                    phase = .born
                }
            }
        }
    }

    // MARK: - Birth Content

    @State private var characterScale: CGFloat = 0.3
    @State private var characterOpacity: Double = 0
    @State private var showHomeButton = false

    private var birthContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("きれいっちが\n生まれました！")
                .font(DesignSystem.Font.title2)
                .foregroundColor(DesignSystem.Color.textPrimary)
                .multilineTextAlignment(.center)

            CharacterView(
                characterType: selectedCharacterType,
                characterState: nil,
                forceGif: .happy
            )
            .frame(width: 280, height: 280)
            .scaleEffect(characterScale)
            .opacity(characterOpacity)

            Spacer()

            if showHomeButton {
                Button {
                    // 家出状態を解除してホームに戻る
                    isInRunawayState = false
                    isPresented = false
                } label: {
                    Text("ホームに戻る")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DesignSystem.Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(DesignSystem.Color.secondary.opacity(0.8))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignSystem.Color.textPrimary, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 40)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer().frame(height: 60)
        }
        .onAppear {
            // キャラクター登場アニメーション（1.5倍まで拡大→1.0倍に戻る）
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                characterScale = 1.5
                characterOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    characterScale = 1.0
                }
            }

            // ホームに戻るボタンを少し遅れて表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showHomeButton = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RunawayEggView(isPresented: .constant(true))
    }
}
