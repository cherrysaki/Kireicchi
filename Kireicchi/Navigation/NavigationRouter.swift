import SwiftUI
import Combine

@MainActor
final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    // 画面遷移用のRouteType
    enum Route: Hashable {
        case capture
        case analyzing(imageData: Data)
        case analysisResult(imageData: Data, pixelArtData: Data, analysis: RoomAnalysis)
        case settings
        case cleanupTimer
    }
    
    // 画面遷移メソッド
    func navigate(to route: Route) {
        path.append(route)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

