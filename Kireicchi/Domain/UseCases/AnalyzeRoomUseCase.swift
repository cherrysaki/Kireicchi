import Foundation

final class AnalyzeRoomUseCase: AnalyzeRoomUseCaseProtocol {
    private let openAIClient: OpenAIClientProtocol
    
    init(openAIClient: OpenAIClientProtocol) {
        self.openAIClient = openAIClient
    }
    
    func execute(imageData: Data) async throws -> RoomAnalysis {
        // OpenAI APIで画像を解析
        let response = try await openAIClient.analyzeRoom(imageData: imageData)
        
        // レスポンスをドメインモデルに変換
        return convertToDomainModel(from: response)
    }
    
    private func convertToDomainModel(from response: RoomAnalysisResponse) -> RoomAnalysis {
        // 観点別スコアの重み付き平均で総合点を算出（段階1はstandardペルソナ固定）
        let weights = EvaluatorPersona.default.weights
        let score = weights.composite(from: response.axes)

        // 総合点からランクを算出
        let rank = CleanlinessRank.fromScore(score)

        // MessyPointを優先度順でソート
        let messyPoints = response.messyPoints
            .sorted { $0.priority > $1.priority }  // 優先度が高い順

        return RoomAnalysis(
            score: score,
            rank: rank,
            messyPoints: messyPoints,
            characterComment: response.characterComment
        )
    }
}