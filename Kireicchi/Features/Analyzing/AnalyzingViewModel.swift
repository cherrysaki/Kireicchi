import Foundation
import SwiftData
import Combine

@MainActor
final class AnalyzingViewModel: AnalyzingViewModelProtocol, ObservableObject {
    @Published var currentStep = 0
    @Published var progress: Double = 0
    @Published var isAnalyzing = true
    @Published var errorMessage: String?
    @Published var errorDetails: (rawResponse: String?, apiKeyPrefix: String?)?

    let steps = ["準備", "解析", "変換", "完了"]
    
    private let analyzeRoomUseCase: AnalyzeRoomUseCaseProtocol
    private let generatePixelArtUseCase: GeneratePixelArtUseCaseProtocol
    private var roomRecordStore: LatestRoomRecordStore?
    private var historyStore: RoomHistoryStoreProtocol?
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

    func setup(roomRecordStore: LatestRoomRecordStore,
               historyStore: RoomHistoryStoreProtocol,
               navigationRouter: NavigationRouter) {
        self.roomRecordStore = roomRecordStore
        self.historyStore = historyStore
        self.navigationRouter = navigationRouter
    }
    
    func startAnalysis(imageData: Data) async {
        currentStep = 0
        progress = 0
        errorMessage = nil
        errorDetails = nil
        isAnalyzing = true

        await performAnalysis(imageData: imageData)
    }

    func retry(imageData: Data) async {
        currentStep = 0
        progress = 0
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
            progress = 0.15

            // ステップ2: AI解析とドット絵変換を並列実行
            currentStep = 1
            // 正確な進捗は取れないため、待機中は上限0.9へ漸近的にクリープさせる
            let ticker = Task { [weak self] in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    guard let self else { return }
                    if self.progress < 0.9 {
                        self.progress += (0.9 - self.progress) * 0.06
                    }
                }
            }
            defer { ticker.cancel() }

            async let analysisResult = analyzeRoomUseCase.execute(imageData: imageData)
            async let pixelArtResult = generatePixelArtUseCase.execute(imageData: imageData)
            let analysis = try await analysisResult
            let pixelData = try await pixelArtResult
            ticker.cancel()
            self.roomAnalysis = analysis
            self.pixelArtData = pixelData

            // ステップ3: ドット絵変換（ローカル処理のため即時完了）
            currentStep = 2
            progress = 0.97

            // ステップ4: 完了
            currentStep = 3
            progress = 1.0
            isAnalyzing = false
            
            // データ保存
            let capturedAt = Date()
            let missions = analysis.messyPoints.map { MissionPersisted(from: $0) }
            if let roomRecordStore = roomRecordStore {
                let messyPointLabels = analysis.messyPoints.map { "\($0.label):\($0.priority)" }
                try roomRecordStore.save(
                    pixelArtImageData: pixelData,
                    originalImageData: imageData,
                    capturedAt: capturedAt,
                    score: analysis.score,
                    comment: analysis.characterComment,
                    missions: missions,
                    messyPointLabels: messyPointLabels
                )
            }
            if let historyStore = historyStore {
                let rank = CleanlinessRank.fromScore(analysis.score).rawValue
                let historyRecord = RoomHistoryRecord(
                    capturedAt: capturedAt,
                    score: analysis.score,
                    rank: rank,
                    pixelArtImageData: pixelData,
                    comment: analysis.characterComment,
                    missions: missions
                )
                try historyStore.save(historyRecord)
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