import Foundation

final class OpenAIClient: OpenAIClientProtocol {
    private let session: URLSession
    private let apiKey: String
    
    private enum Constants {
        static let baseURL = "https://api.openai.com/v1"
        static let chatCompletionsEndpoint = "/chat/completions"
        static let imagesEditsEndpoint = "/images/edits"
        static let imageGenerationTimeout: TimeInterval = 120
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
            
            let rawResponseString = String(data: data, encoding: .utf8) ?? "読み取り不可"
            
            guard 200...299 ~= httpResponse.statusCode else {
                // 認証エラーの特別処理
                if httpResponse.statusCode == 401 {
                    let apiKeyPrefix = String(apiKey.prefix(8))
                    throw OpenAIClientError.authenticationError(apiKeyPrefix: apiKeyPrefix)
                }
                throw OpenAIClientError.httpError(httpResponse.statusCode, rawResponseString)
            }
            
            // デバッグ: 生のレスポンス文字列をログ出力
            print("=== OpenAI Raw Response ===")
            print(rawResponseString)
            print("===========================")
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let analysisResponse = try RoomAnalysisResponseParser.parse(from: openAIResponse)
                return analysisResponse
            } catch let decodingError {
                throw OpenAIClientError.jsonDecodingFailed(error: decodingError, rawResponse: rawResponseString)
            }
            
        } catch let error as OpenAIClientError {
            throw error
        } catch let error as RoomAnalysisError {
            throw error
        } catch {
            throw OpenAIClientError.networkError(error)
        }
    }

    func generatePixelArt(imageData: Data) async throws -> Data {
        let url = URL(string: Constants.baseURL + Constants.imagesEditsEndpoint)!
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Constants.imageGenerationTimeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let pixelArtRequest = PixelArtRequest(imageData: imageData)
        request.httpBody = pixelArtRequest.multipartBody(boundary: boundary)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenAIClientError.invalidResponse
            }

            let rawResponseString = String(data: data, encoding: .utf8) ?? "読み取り不可"
            
            guard 200...299 ~= httpResponse.statusCode else {
                // 認証エラーの特別処理
                if httpResponse.statusCode == 401 {
                    let apiKeyPrefix = String(apiKey.prefix(8))
                    throw OpenAIClientError.authenticationError(apiKeyPrefix: apiKeyPrefix)
                }
                throw OpenAIClientError.httpError(httpResponse.statusCode, rawResponseString)
            }

            do {
                let decoded = try JSONDecoder().decode(PixelArtResponse.self, from: data)
                return try PixelArtResponseParser.extractImageData(from: decoded)
            } catch let decodingError {
                throw OpenAIClientError.jsonDecodingFailed(error: decodingError, rawResponse: rawResponseString)
            }

        } catch let error as OpenAIClientError {
            throw error
        } catch let error as PixelArtError {
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
    case jsonDecodingFailed(error: Error, rawResponse: String)
    case authenticationError(apiKeyPrefix: String)
    
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
        case .jsonDecodingFailed(let error, let rawResponse):
            return "JSONデコードエラー: \(error.localizedDescription)"
        case .authenticationError(let apiKeyPrefix):
            return "認証エラー (APIキー: \(apiKeyPrefix)...)"
        }
    }
    
    var rawResponse: String? {
        switch self {
        case .jsonDecodingFailed(_, let rawResponse):
            return rawResponse
        case .httpError(_, let message):
            return message
        default:
            return nil
        }
    }
    
    var apiKeyPrefix: String? {
        switch self {
        case .authenticationError(let prefix):
            return prefix
        default:
            return nil
        }
    }
}