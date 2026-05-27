import SwiftUI

struct RootView: View {
    @StateObject private var navigationRouter = NavigationRouter()
    @EnvironmentObject private var deps: AppDependencies
    @Environment(\.modelContext) private var modelContext

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
                            myDisplayName: deps.currentUser?.displayName ?? "わたし",
                            myCharacterId: UserDefaults.standard.string(forKey: "selectedCharacterID") ?? CharacterType.character01.rawValue
                        )
                    case .history:
                        HistoryView(viewModel: HistoryViewModel(
                            historyStore: RoomHistoryStore(context: modelContext)
                        ))
                    }
                }
        }
        .environmentObject(navigationRouter)
        .safeAreaInset(edge: .top) {
            if let message = deps.bootstrapError {
                RetryBanner(message: message) {
                    Task { await deps.bootstrap() }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: deps.bootstrapError)
    }
}
