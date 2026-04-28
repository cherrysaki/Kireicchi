import Foundation
import Combine

@MainActor
final class MockAnalyzingViewModel: AnalyzingViewModelProtocol, ObservableObject {
    @Published var currentStep = 0
    @Published var isAnalyzing = true
    @Published var errorMessage: String?
    @Published var errorDetails: (rawResponse: String?, apiKeyPrefix: String?)?
    
    let steps = ["準備中", "AI解析中", "ドット絵変換中", "完了"]
    
    private let shouldSucceed: Bool
    private let delay: TimeInterval
    
    init(shouldSucceed: Bool = true, delay: TimeInterval = 1.0) {
        self.shouldSucceed = shouldSucceed
        self.delay = delay
    }
    
    func startAnalysis(imageData: Data) async {
        await performMockAnalysis()
    }
    
    func retry(imageData: Data) async {
        currentStep = 0
        errorMessage = nil
        errorDetails = nil
        isAnalyzing = true
        await performMockAnalysis()
    }
    
    private func performMockAnalysis() async {
        currentStep = 0
        
        for step in 0..<steps.count {
            currentStep = step
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            if step == 2 && !shouldSucceed {
                isAnalyzing = false
                errorMessage = "JSONデコードエラー: Mock simulated error"
                errorDetails = (
                    rawResponse: """
                    {
                      "error": {
                        "message": "Mock API error for testing",
                        "type": "mock_error",
                        "code": "test_failure"
                      }
                    }
                    """,
                    apiKeyPrefix: "sk-mock-12"
                )
                return
            }
        }
        
        isAnalyzing = false
    }
}