import SwiftUI

struct FriendVisitView: View {
    @EnvironmentObject var navigationRouter: NavigationRouter
    @StateObject private var viewModel: FriendVisitViewModel

    @AppStorage("selectedCharacterID") private var selectedCharacterTypeRaw: String = CharacterType.character01.rawValue

    init(myDisplayName: String, myCharacterId: String) {
        let coordinator = AppDependencies.shared.makeFriendVisitCoordinator()
        _viewModel = StateObject(wrappedValue: FriendVisitViewModel(
            coordinator: coordinator,
            myCharacterId: myCharacterId,
            myDisplayName: myDisplayName
        ))
    }

    private var myCharacterType: CharacterType {
        CharacterType(rawValue: selectedCharacterTypeRaw) ?? .character01
    }

    var body: some View {
        ZStack {
            DesignSystem.Color.background.ignoresSafeArea()

            VStack(spacing: 16) {
                topBar
                statusHeadline
                sharedRoom
                distanceGauge
                connectionFooter
                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                navigationRouter.navigateBack()
            }) {
                Image(systemName: "xmark")
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        PixelCircle(pixelSize: 3)
                            .fill(DesignSystem.Color.surface)
                    )
                    .overlay(
                        PixelCircleStroke(pixelSize: 3, lineWidth: 3)
                            .fill(DesignSystem.Color.primary)
                    )
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    // MARK: - Status Headline
    private var statusHeadline: some View {
        VStack(spacing: 4) {
            Text("🫂 ともだちと あう")
                .font(DesignSystem.Font.caption)
                .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            Text(viewModel.state.headlineText)
                .font(DesignSystem.Font.title2)
                .foregroundColor(headlineColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var headlineColor: Color {
        switch viewModel.state {
        case .visiting:           return DesignSystem.Color.primary
        case .error:              return DesignSystem.Color.accentWarm
        default:                  return DesignSystem.Color.textPrimary
        }
    }

    // MARK: - Shared Room
    private var sharedRoom: some View {
        ZStack {
            Rectangle()
                .fill(DesignSystem.Color.secondary.opacity(0.3))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Rectangle()
                        .stroke(DesignSystem.Color.primary, lineWidth: 3)
                )

            HStack(spacing: 24) {
                CharacterView(
                    characterType: myCharacterType,
                    characterState: .happy
                )
                .frame(width: 200, height: 200)

                if let friend = viewModel.friend, isVisitingState {
                    CharacterView(
                        characterType: friend.characterType,
                        characterState: .happy,
                        forceGif: .cheer
                    )
                    .frame(width: 200, height: 200)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.4), value: isVisitingState)

            if isVisitingState {
                Text("✨")
                    .font(DesignSystem.Font.custom(size: 40))
                    .offset(x: 0, y: -80)
            }
        }
        .padding(.horizontal)
        .padding(.trailing, 4)
    }

    private var isVisitingState: Bool {
        if case .visiting = viewModel.state { return true }
        return false
    }

    // MARK: - Distance Gauge
    private var distanceGauge: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(gaugeFillColor(for: index))
                        .frame(height: 14)
                }
            }
            .padding(.horizontal, 4)
            .overlay(
                Rectangle()
                    .stroke(DesignSystem.Color.primaryDark, lineWidth: 2)
            )
            .padding(.horizontal)
            .padding(.trailing, 3)

            HStack {
                Text("ちかい")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
                Spacer()
                if let d = viewModel.distance {
                    Text(String(format: "%.1f m", d))
                        .font(DesignSystem.Font.caption)
                        .foregroundColor(DesignSystem.Color.primaryDark)
                }
                Spacer()
                Text("とおい")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            }
            .padding(.horizontal)
        }
    }

    private func gaugeFillColor(for index: Int) -> Color {
        guard let d = viewModel.distance else {
            return DesignSystem.Color.secondary.opacity(0.3)
        }
        // 距離(0〜3m)を 8 段階にマップ。近いほど左側が埋まる
        let clamped = max(0, min(3.0, d))
        let filledCount = Int((1.0 - clamped / 3.0) * 8.0)
        return index < filledCount
            ? DesignSystem.Color.primary
            : DesignSystem.Color.secondary.opacity(0.3)
    }

    // MARK: - Connection Footer
    @ViewBuilder
    private var connectionFooter: some View {
        if let friend = viewModel.friend {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .foregroundColor(DesignSystem.Color.primary)
                Text(friend.displayName)
                    .font(DesignSystem.Font.subheadline)
                    .foregroundColor(DesignSystem.Color.textPrimary)
                Text("と つながりました")
                    .font(DesignSystem.Font.caption)
                    .foregroundColor(DesignSystem.Color.textPrimary.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .pixelSquareCard(
                fill: DesignSystem.Color.surface,
                border: DesignSystem.Color.primary,
                borderWidth: 2,
                shadowOffset: 3
            )
            .padding(.horizontal)
            .padding(.trailing, 3)
        }
    }
}

#Preview("Visiting") {
    NavigationStack {
        FriendVisitView(myDisplayName: "わたし", myCharacterId: CharacterType.character01.rawValue)
            .environmentObject(NavigationRouter())
    }
}
