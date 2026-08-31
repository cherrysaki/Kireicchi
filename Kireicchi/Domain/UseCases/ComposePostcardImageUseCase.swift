import UIKit

/// 部屋のドット絵にキャラクターの静止画を合成してポストカード画像（PNG）を作る。
/// 配置はホーム画面の roomFrame と同じ（幅の50%、下寄せ）。
final class ComposePostcardImageUseCase: ComposePostcardImageUseCaseProtocol {
    private static let outputSize: CGFloat = 512
    // ホームは幅50%の正方形ボックスに 800x450 のGIFを aspectFit するため、
    // キャラの実表示高さは部屋幅の約28% (0.5 * 450/800)。静止画はそれに合わせて高さ基準で描く。
    private static let characterHeightScale: CGFloat = 0.5 * 450.0 / 800.0
    private static let bottomPaddingRatio: CGFloat = 8.0 / 360.0

    func execute(pixelArtData: Data, characterType: CharacterType, characterState: CharacterState) -> Data {
        guard let room = UIImage(data: pixelArtData) else { return pixelArtData }
        let side = Self.outputSize
        let canvas = CGRect(x: 0, y: 0, width: side, height: side)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: canvas.size, format: format)

        let image = renderer.image { context in
            let cg = context.cgContext
            cg.interpolationQuality = .none
            room.draw(in: canvas)

            let name = "\(characterType.rawValue)_\(characterState.gifSuffix)_static"
            guard let character = UIImage(named: name) else { return }
            let height = side * Self.characterHeightScale
            let width = height * (character.size.width / max(character.size.height, 1))
            let origin = CGPoint(
                x: (side - width) / 2,
                y: side - height - side * Self.bottomPaddingRatio
            )
            cg.interpolationQuality = .none
            character.draw(in: CGRect(origin: origin, size: CGSize(width: width, height: height)))
        }
        return image.pngData() ?? pixelArtData
    }
}
