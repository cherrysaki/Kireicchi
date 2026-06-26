import SwiftUI

struct RootView: View {
    @StateObject private var navigationRouter = NavigationRouter()
    @EnvironmentObject private var deps: AppDependencies
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasShownLogoSplash") private var hasShownLogoSplash: Bool = false
    @AppStorage("hasShownWorldviewOnboarding") private var hasShownWorldviewOnboarding: Bool = false
    @AppStorage("hasShownTutorial") private var hasShownTutorial: Bool = false
    @AppStorage("hasCompletedOwnerRegistration") private var hasCompletedOwnerRegistration: Bool = false

    var body: some View {
        if !hasShownWorldviewOnboarding {
            WorldviewOnboardingView()
        } else if !hasCompletedOwnerRegistration {
            OwnerRegistrationView()
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
                            myDisplayName: deps.currentUser?.username ?? deps.currentUser?.displayName ?? "私",
                            myCharacterId: UserDefaults.standard.string(forKey: "selectedCharacterID") ?? CharacterType.character01.rawValue
                        )
                    case .recordDetail(let record):
                        RecordDetailView(record: record)
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
