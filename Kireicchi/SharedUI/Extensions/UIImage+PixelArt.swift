import UIKit

extension UIImage {
    /// 撮影画像をドット絵化する（縮小＋色相を保つ量子化）。
    ///
    /// 表示側は `.interpolation(.none)` でニアレスト拡大する前提のため、ここでは
    /// 小さなピクセルグリッドそのものを生成して返す。出力解像度＝ドットの粗さ。
    ///
    /// 減色は `PixelArtColorQuantizer` に委譲する（無彩色保護＋Median Cut＋Lab最近傍）。
    /// チャンネル独立のRGB量子化は色相を壊すため使わない。
    ///
    /// - Parameters:
    ///   - gridSize: 縮小後の一辺ピクセル数。小さいほど粗いドット絵になる。
    ///   - paletteSize: 有彩色パレットの最大色数。
    ///   - grayLevels: 無彩色グレーランプの段数。
    ///   - satThreshold: これ未満の彩度を無彩色（グレー）として扱う（0...1）。
    ///   - neutralize: 全体の色かぶりを穏やかに中立化する。
    func pixelated(gridSize: Int = 128,
                   paletteSize: Int = 18,
                   grayLevels: Int = 6,
                   satThreshold: Double = 0.12,
                   neutralize: Bool = false) -> UIImage? {
        let side = max(8, gridSize)
        let targetSize = CGSize(width: side, height: side)

        // 1. 縮小（draw(in:) が orientation を吸収して .up に正規化する）
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let small = UIGraphicsImageRenderer(size: targetSize, format: format).image { ctx in
            ctx.cgContext.interpolationQuality = .medium
            draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard let cg = small.cgImage else { return nil }
        let width = cg.width
        let height = cg.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        // 2. sRGB の既知フォーマット（8bit RGBA）へ描画して生ピクセルを取得。
        //    sRGB を明示して P3 カメラ画像の neutrals が転ばないようにする。
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: height * bytesPerRow)

        // 3. 色相を保つ量子化（無彩色保護＋Median Cut＋Lab最近傍）
        PixelArtColorQuantizer.quantize(
            ptr: ptr,
            pixelCount: width * height,
            paletteSize: paletteSize,
            grayLevels: grayLevels,
            satThreshold: satThreshold,
            neutralize: neutralize
        )

        // 4. 再構成
        guard let outCG = context.makeImage() else { return nil }
        return UIImage(cgImage: outCG, scale: 1, orientation: .up)
    }
}
