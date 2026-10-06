import SwiftUI

struct CharacterView: View {
    let characterType: CharacterType
    let formID: CharacterFormID
    let mood: CharacterMood
    let playbackMode: CharacterPlaybackMode

    @State private var showingWalk = false
    @State private var timer: Timer?

    private let appearanceResolver = CharacterAppearanceResolver()

    init(
        characterType: CharacterType,
        formID: CharacterFormID = .base,
        mood: CharacterMood = .happy,
        playbackMode: CharacterPlaybackMode = .homeIdle
    ) {
        self.characterType = characterType
        self.formID = formID
        self.mood = mood
        self.playbackMode = playbackMode
    }

    var body: some View {
        AnimatedGIFView(assetName: currentAssetName)
            .onAppear {
                if playbackMode == .homeIdle {
                    startHomeIdleTimer()
                }
            }
            .onDisappear {
                stopHomeIdleTimer()
            }
            .onChange(of: playbackMode) { _, newMode in
                if newMode == .homeIdle {
                    startHomeIdleTimer()
                } else {
                    stopHomeIdleTimer()
                }
            }
    }

    private var currentAction: CharacterAction {
        switch playbackMode {
        case .homeIdle:
            return showingWalk ? .walk : .idle
        case .fixed(let action):
            return action
        }
    }

    private var currentAssetName: String {
        let presentation = appearanceResolver.resolve(
            characterType: characterType,
            formID: formID,
            mood: mood,
            action: currentAction
        )
        return CharacterAssetCatalog.shared.assetName(for: presentation)
    }

    private func startHomeIdleTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation {
                showingWalk.toggle()
            }
        }
    }

    private func stopHomeIdleTimer() {
        timer?.invalidate()
        timer = nil
        showingWalk = false
    }
}

#Preview {
    VStack(spacing: 20) {
        CharacterView(characterType: .character01, mood: .happy)
            .frame(width: 100, height: 100)

        CharacterView(characterType: .character01, mood: .normal)
            .frame(width: 100, height: 100)

        CharacterView(characterType: .character01, mood: .sad)
            .frame(width: 100, height: 100)

        CharacterView(
            characterType: .character01,
            playbackMode: .fixed(.cheer)
        )
        .frame(width: 100, height: 100)
    }
    .padding()
}
