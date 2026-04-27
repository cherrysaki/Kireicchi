import Foundation
import Combine

@MainActor
final class AppDependencies: ObservableObject {
    @Published var useMockAPI: Bool = true
    
    // Singleton
    static let shared = AppDependencies()
    
    private init() {}
    
    // Mock/Real APIを切り替えるメソッド
    func currentOpenAIClient() -> OpenAIClientProtocol {
        if useMockAPI {
            return MockOpenAIClient()
        } else {
            return OpenAIClient()
        }
    }
    
    // デバッグ用のトグルメソッド
    func toggleMockAPI() {
        useMockAPI.toggle()
    }
}