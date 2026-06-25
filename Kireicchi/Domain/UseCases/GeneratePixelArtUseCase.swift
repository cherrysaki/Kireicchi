import UIKit

final class GeneratePixelArtUseCase: GeneratePixelArtUseCaseProtocol {
    /// 縮小後の一辺ピクセル数（ドットの粗さ）。
    private let gridSize: Int
    /// 有彩色パレットの最大色数。
    private let paletteSize: Int
    /// 無彩色グレーランプの段数。
    private let grayLevels: Int
    /// これ未満の彩度を無彩色（グレー）として扱う（0...1）。
    private let satThreshold: Double
    /// 全体の色かぶりを穏やかに中立化する。
    private let neutralize: Bool

    init(gridSize: Int = 128, paletteSize: Int = 18,
         grayLevels: Int = 6, satThreshold: Double = 0.12,
         neutralize: Bool = false) {
        self.gridSize = gridSize
        self.paletteSize = paletteSize
        self.grayLevels = grayLevels
        self.satThreshold = satThreshold
        self.neutralize = neutralize
    }

    func execute(imageData: Data) async throws -> Data {
        let gridSize = self.gridSize
        let paletteSize = self.paletteSize
        let grayLevels = self.grayLevels
        let satThreshold = self.satThreshold
        let neutralize = self.neutralize
        return try await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: imageData) else {
                throw PixelArtGenerationError.invalidImageData
            }
            guard let pixelData = image.pixelated(
                gridSize: gridSize, paletteSize: paletteSize,
                grayLevels: grayLevels, satThreshold: satThreshold,
                neutralize: neutralize
            )?.pngData() else {
                throw PixelArtGenerationError.processingFailed
            }
            return pixelData
        }.value
    }
}
