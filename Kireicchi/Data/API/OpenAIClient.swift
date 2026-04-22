import Foundation

final class OpenAIClient: OpenAIClientProtocol {
    private let session: URLSession
    private let apiKey: String
    
    private enum Constants {
        static let baseURL = "https://api.openai.com/v1"
        static let chatCompletionsEndpoint = "/chat/completions"
    }
    
    init(session: URLSession = .shared) {
        self.session = session
        self.apiKey = AppConfig.openAIAPIKey
    }
    
    func analyzeRoom(imageData: Data) async throws -> RoomAnalysisResponse {
        let url = URL(string: Constants.baseURL + Constants.chatCompletionsEndpoint)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = RoomAnalysisRequest(imageData: imageData)
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw OpenAIClientError.encodingFailed(error)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIClientError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw OpenAIClientError.httpError(httpResponse.statusCode, errorMessage)
            }
            
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            let analysisResponse = try RoomAnalysisResponseParser.parse(from: openAIResponse)
            
            return analysisResponse
            
        } catch let error as OpenAIClientError {
            throw error
        } catch let error as RoomAnalysisError {
            throw error
        } catch {
            throw OpenAIClientError.networkError(error)
        }
    }
}

enum OpenAIClientError: LocalizedError {
    case encodingFailed(Error)
    case invalidResponse
    case httpError(Int, String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "リクエストのエンコードに失敗しました: \(error.localizedDescription)"
        case .invalidResponse:
            return "無効なレスポンス形式です"
        case .httpError(let statusCode, let message):
            return "HTTP エラー \(statusCode): \(message)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        }
    }
}