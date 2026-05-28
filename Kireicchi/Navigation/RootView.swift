import SwiftUI

struct RootView: View {
    @StateObject private var navigationRouter = NavigationRouter()
    @EnvironmentObject private var deps: AppDependencies
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasShownTutorial") private var hasShownTutorial: Bool = false

    var body: some View {
        if !hasShownTutorial {
            TutorialView()
        } else {
            mainStack
        }
    }

    private var mainStack: some View {
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
                    case .history:
                        HistoryView(viewModel: HistoryViewModel(
                            historyStore: RoomHistoryStore(context: modelContext)
                        ))
                    case .friendVisit:
                        FriendVisitView(
                            myDisplayName: deps.currentUser?.displayName ?? "わたし",
                            myCharacterId: UserDefaults.standard.string(forKey: "selectedCharacterID") ?? CharacterType.character01.rawValue
                        )
                    }
                }
        }
        .environmentObject(navigationRouter)
    }
}
