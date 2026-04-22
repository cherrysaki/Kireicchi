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
        // CLAUDE.mdのスコアリングルールに従ってランクを算出
        let rank = CleanlinessRank.fromScore(response.score)
        
        // MessyPointをStringの配列に変換（優先度順でソート）
        let messyPoints = response.messyPoints
            .sorted { $0.priority > $1.priority }  // 優先度が高い順
            .map { $0.label }
        
        return RoomAnalysis(
            score: response.score,
            rank: rank,
            messyPoints: messyPoints,
            characterComment: response.characterComment
        )
    }
}