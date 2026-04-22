import SwiftUI
import Combine

@MainActor
final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    // 画面遷移用のRouteType
    enum Route: Hashable {
        case capture
        case analyzing(imageData: Data)
        case analysisResult(imageData: Data, analysis: RoomAnalysis)
        case settings
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

// RoomAnalysis仮定義（後でDomainに移動）
struct RoomAnalysis: Hashable {
    let score: Int
    let rank: CleanlinessRank
    let messyPoints: [String]
    let characterComment: String
}

enum CleanlinessRank: String, CaseIterable, Hashable {
    case a = "A"
    case b = "B" 
    case c = "C"
    case d = "D"
    case e = "E"
    
    static func fromScore(_ score: Int) -> CleanlinessRank {
        switch score {
        case 85...100: return .a
        case 70...84: return .b
        case 50...69: return .c
        case 30...49: return .d
        default: return .e
        }
    }
}