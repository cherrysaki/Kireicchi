import Foundation

enum PixelArtGenerationError: LocalizedError {
    case invalidImageData
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "画像の読み込みに失敗しました。"
        case .processingFailed:
            return "ドット絵の生成に失敗しました。"
        }
    }
}
