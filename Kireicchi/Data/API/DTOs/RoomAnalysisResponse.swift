import Foundation

// OpenAI APIのレスポンス全体
struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: ResponseMessage
        
        struct ResponseMessage: Codable {
            let content: String
        }
    }
}

// 部屋解析結果のデータ構造（OpenAIが返すJSON）
struct RoomAnalysisResponse: Codable {
    let score: Int
    let messyPoints: [MessyPoint]
    let characterComment: String
    
    private enum CodingKeys: String, CodingKey {
        case score
        case messyPoints = "messy_points"
        case characterComment = "character_comment"
    }
}


// OpenAI APIレスポンスから部屋解析結果を抽出するためのパーサー
struct RoomAnalysisResponseParser {
    static func parse(from openAIResponse: OpenAIResponse) throws -> RoomAnalysisResponse {
        guard let firstChoice = openAIResponse.choices.first else {
            throw RoomAnalysisError.noChoicesInResponse
        }
        
        let content = firstChoice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // JSONのみを抽出（markdown記法などを除去）
        let cleanedContent = extractJSON(from: content)
        
        guard let jsonData = cleanedContent.data(using: .utf8) else {
            throw RoomAnalysisError.invalidJSONFormat
        }
        
        do {
            let analysisResponse = try JSONDecoder().decode(RoomAnalysisResponse.self, from: jsonData)
            
            // バリデーション
            try validate(analysisResponse)
            
            return analysisResponse
        } catch {
            // デバッグ: JSONデコード失敗時の詳細ログ
            print("=== JSON Decode Error ===")
            print(error)
            print("========================")
            throw RoomAnalysisError.jsonDecodingFailed(error)
        }
    }
    
    private static func extractJSON(from content: String) -> String {
        // マークダウンのコードブロックを除去
        let withoutMarkdown = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // JSON部分のみを抽出
        if let jsonStart = withoutMarkdown.firstIndex(of: "{"),
           let jsonEnd = withoutMarkdown.lastIndex(of: "}") {
            return String(withoutMarkdown[jsonStart...jsonEnd])
        }
        
        return withoutMarkdown
    }
    
    private static func validate(_ response: RoomAnalysisResponse) throws {
        // スコアの範囲チェック
        guard response.score >= 0 && response.score <= 100 else {
            throw RoomAnalysisError.invalidScore(response.score)
        }
        
        // priorityの範囲チェック
        for messyPoint in response.messyPoints {
            guard messyPoint.priority >= 1 && messyPoint.priority <= 5 else {
                throw RoomAnalysisError.invalidPriority(messyPoint.priority)
            }
        }
        
        // コメント長チェック
        guard response.characterComment.count <= 20 else {
            throw RoomAnalysisError.commentTooLong(response.characterComment.count)
        }
    }
}

// エラー定義
enum RoomAnalysisError: LocalizedError {
    case noChoicesInResponse
    case invalidJSONFormat
    case jsonDecodingFailed(Error)
    case invalidScore(Int)
    case invalidPriority(Int)
    case commentTooLong(Int)
    
    var errorDescription: String? {
        switch self {
        case .noChoicesInResponse:
            return "OpenAI APIのレスポンスにchoicesが含まれていません"
        case .invalidJSONFormat:
            return "レスポンスのJSON形式が無効です"
        case .jsonDecodingFailed(let error):
            return "JSONのデコードに失敗しました: \(error.localizedDescription)"
        case .invalidScore(let score):
            return "スコアが範囲外です: \(score) (0-100)"
        case .invalidPriority(let priority):
            return "優先度が範囲外です: \(priority) (1-5)"
        case .commentTooLong(let length):
            return "コメントが長すぎます: \(length)文字 (20文字以内)"
        }
    }
}