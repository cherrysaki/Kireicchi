import Foundation

@MainActor
protocol AnalyzingViewModelProtocol: ObservableObject {
    var currentStep: Int { get }
    var isAnalyzing: Bool { get }
    var errorMessage: String? { get }
    var errorDetails: (rawResponse: String?, apiKeyPrefix: String?)? { get }
    var steps: [String] { get }
    
    func startAnalysis(imageData: Data) async
    func retry(imageData: Data) async
}