import Foundation
import SwiftData
import Combine

@MainActor
final class AnalyzingViewModel: AnalyzingViewModelProtocol, ObservableObject {
    @Published var currentStep = 0
    @Published var isAnalyzing = true
    @Published var errorMessage: String?
    @Published var errorDetails: (rawResponse: String?, apiKeyPrefix: String?)?
    
    let steps = ["準備中", "AI解析中", "ドット絵変換中", "完了"]
    
    private let analyzeRoomUseCase: AnalyzeRoomUseCaseProtocol
    private let generatePixelArtUseCase: GeneratePixelArtUseCaseProtocol
    private var roomRecordStore: LatestRoomRecordStore?
    private var navigationRouter: NavigationRouter?
    
    // 解析結果を保持
    private var roomAnalysis: RoomAnalysis?
    private var pixelArtData: Data?
    
    init(
        analyzeRoomUseCase: AnalyzeRoomUseCaseProtocol,
        generatePixelArtUseCase: GeneratePixelArtUseCaseProtocol
    ) {
        self.analyzeRoomUseCase = analyzeRoomUseCase
        self.generatePixelArtUseCase = generatePixelArtUseCase
    }
    
    func setup(roomRecordStore: LatestRoomRecordStore, navigationRouter: NavigationRouter) {
        self.roomRecordStore = roomRecordStore
        self.navigationRouter = navigationRouter
    }
    
    func startAnalysis(imageData: Data) async {
        currentStep = 0
        errorMessage = nil
        errorDetails = nil
        isAnalyzing = true
        
        await performAnalysis(imageData: imageData)
    }
    
    func retry(imageData: Data) async {
        currentStep = 0
        errorMessage = nil
        errorDetails = nil
        isAnalyzing = true
        roomAnalysis = nil
        pixelArtData = nil
        
        await performAnalysis(imageData: imageData)
    }
    
    private func performAnalysis(imageData: Data) async {
        do {
            // ステップ1: 準備
            currentStep = 0
            try await Task.sleep(nanoseconds: 300_000_000)
            
            // ステップ2: AI解析
            currentStep = 1
            let analysis = try await analyzeRoomUseCase.execute(imageData: imageData)
            self.roomAnalysis = analysis
            
            // ステップ3: ドット絵変換
            currentStep = 2
            let pixelData = try await generatePixelArtUseCase.execute(imageData: imageData)
            self.pixelArtData = pixelData
            
            // ステップ4: 完了
            currentStep = 3
            isAnalyzing = false
            
            // データ保存
            if let roomRecordStore = roomRecordStore {
                let messyPointLabels = analysis.messyPoints.map { "\($0.label):\($0.priority)" }
                try roomRecordStore.save(
                    pixelArtImageData: pixelData,
                    capturedAt: Date(),
                    score: analysis.score,
                    comment: analysis.characterComment,
                    messyPointLabels: messyPointLabels
                )
            }
            
            // 少し待ってから結果画面に遷移
            try await Task.sleep(nanoseconds: 500_000_000)
            
            navigationRouter?.navigate(to: .analysisResult(
                imageData: imageData,
                pixelArtData: pixelData,
                analysis: analysis
            ))
            
        } catch {
            isAnalyzing = false
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            
            // OpenAIClientErrorの詳細情報を抽出
            if let openAIError = error as? OpenAIClientError {
                errorDetails = (
                    rawResponse: openAIError.rawResponse,
                    apiKeyPrefix: openAIError.apiKeyPrefix
                )
            } else {
                errorDetails = nil
            }
        }
    }
}