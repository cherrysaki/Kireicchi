import Foundation

struct PixelArtResponse: Codable {
    let data: [ImageData]

    struct ImageData: Codable {
        let b64Json: String?

        private enum CodingKeys: String, CodingKey {
            case b64Json = "b64_json"
        }
    }
}

struct PixelArtResponseParser {
    static func extractImageData(from response: PixelArtResponse) throws -> Data {
        guard let first = response.data.first else {
            throw PixelArtError.noImagesInResponse
        }
        guard let b64 = first.b64Json, !b64.isEmpty else {
            throw PixelArtError.missingB64Json
        }
        guard let imageData = Data(base64Encoded: b64) else {
            throw PixelArtError.invalidBase64
        }
        return imageData
    }
}

enum PixelArtError: LocalizedError {
    case noImagesInResponse
    case missingB64Json
    case invalidBase64

    var errorDescription: String? {
        switch self {
        case .noImagesInResponse:
            return "画像生成のレスポンスが空です"
        case .missingB64Json:
            return "レスポンスに画像データが含まれていません"
        case .invalidBase64:
            return "画像のbase64デコードに失敗しました"
        }
    }
}
