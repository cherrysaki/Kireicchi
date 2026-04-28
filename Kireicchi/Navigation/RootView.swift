import SwiftUI

struct RootView: View {
    @StateObject private var navigationRouter = NavigationRouter()

    var body: some View {
        NavigationStack(path: $navigationRouter.path) {
            HomeView()
                .navigationDestination(for: NavigationRouter.Route.self) { route in
                    switch route {
                    case .capture:
                        CaptureView()
                    case .analyzing(let imageData):
                        AnalyzingView(imageData: imageData)
                    case .analysisResult(let imageData, let pixelArtData, let analysis):
                        AnalysisResultView(imageData: imageData, pixelArtData: pixelArtData, analysis: analysis)
                    case .settings:
                        SettingsView()
                    case .cleanupTimer:
                        CleanupTimerView()
                    case .friendVisit:
                        FriendVisitView(
                            myDisplayName: AppDependencies.shared.currentUser?.displayName ?? "わたし",
                            myCharacterId: UserDefaults.standard.string(forKey: "selectedCharacterID") ?? CharacterType.character01.rawValue
                        )
                    }
                }
        }
        .environmentObject(navigationRouter)
    }
}