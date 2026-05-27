import SwiftUI

struct RootView: View {
    @StateObject private var navigationRouter = NavigationRouter()
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
                    }
                }
        }
        .environmentObject(navigationRouter)
    }
}
