import UIKit
import CoreImage

extension UIImage {
    /// 撮影画像をドット絵化する（前処理＋縮小＋色相を保つ量子化）。
    ///
    /// 表示側は `.interpolation(.none)` でニアレスト拡大する前提のため、ここでは
    /// 小さなピクセルグリッドそのものを生成して返す。出力解像度＝ドットの粗さ。
    ///
    /// 縮小前に Core Image でエッジ保持スムージング＋彩度/コントラスト強調を行う。
    /// 写真の高周波ディテール（紙・文字・布の質感）をそのまま縮小すると斑点ノイズが残り、
    /// 低彩度の被写体が無彩色判定でグレーに潰れて全体がくすむため、先に平らな色面へ均し、
    /// 色を立ててから縮小・減色する。
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

        // 0. 前処理（Core Image）：彩度/コントラスト強調＋エッジ保持スムージング。
        //    失敗時は self を使って従来パスにフォールバックする。
        let preprocessed = preprocessedForPixelArt() ?? self

        // 1. 縮小（draw(in:) が orientation を吸収して .up に正規化する）
        //    .medium（バイリニア）で縮小する。.high(Lanczos) は高コントラスト境界に
        //    リンギング（ハロー＝滲み）を出すため、ドット境目を立てる目的では避ける。
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let small = UIGraphicsImageRenderer(size: targetSize, format: format).image { ctx in
            ctx.cgContext.interpolationQuality = .medium
            preprocessed.draw(in: CGRect(origin: .zero, size: targetSize))
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

    /// ドット絵化の前処理。彩度/コントラストを上げて色を立て、エッジ保持スムージングで
    /// 紙・文字・布などの高周波ディテールを平らな色面に均す。失敗時は nil（呼び出し側で self に退避）。
    private func preprocessedForPixelArt() -> UIImage? {
        guard let cg = cgImage else { return nil }
        // orientation を吸収するため CGImage 経由で CIImage 化（draw 同様 .up 前提）。
        let input = CIImage(cgImage: cg)

        // 彩度・コントラスト強調（3枚目相当=中）。
        guard let colorControls = CIFilter(name: "CIColorControls") else { return nil }
        colorControls.setValue(input, forKey: kCIInputImageKey)
        colorControls.setValue(PixelArtPreprocess.saturation, forKey: kCIInputSaturationKey)
        colorControls.setValue(PixelArtPreprocess.contrast, forKey: kCIInputContrastKey)
        colorControls.setValue(PixelArtPreprocess.brightness, forKey: kCIInputBrightnessKey)
        guard let saturated = colorControls.outputImage else { return nil }

        // エッジ保持スムージング（質感のフラット化）。生成不可なら強調のみで続行。
        let smoothed: CIImage
        if let noise = CIFilter(name: "CINoiseReduction") {
            noise.setValue(saturated, forKey: kCIInputImageKey)
            noise.setValue(PixelArtPreprocess.noiseLevel, forKey: "inputNoiseLevel")
            noise.setValue(PixelArtPreprocess.sharpness, forKey: "inputSharpness")
            smoothed = noise.outputImage ?? saturated
        } else {
            smoothed = saturated
        }

        // CINoiseReduction は端の数px分 extent が縮むため、元画像範囲にクランプする。
        let output = smoothed.cropped(to: input.extent)
        guard let outCG = UIImage.sharedCIContext.createCGImage(output, from: input.extent) else {
            return nil
        }
        return UIImage(cgImage: outCG, scale: scale, orientation: .up)
    }

    /// 前処理用の CIContext（生成コストが高いため使い回す）。
    private static let sharedCIContext = CIContext(options: [.useSoftwareRenderer: false])
}

/// ドット絵化前処理のチューニング定数。実機で見た目を調整する場合はここを変える。
private enum PixelArtPreprocess {
    /// 彩度。1.0 が等倍。3枚目相当の鮮やかさ。
    static let saturation: CGFloat = 1.35
    /// コントラスト。1.0 が等倍。
    static let contrast: CGFloat = 1.08
    /// 明度。0 が等倍。
    static let brightness: CGFloat = 0
    /// ノイズ除去の強さ（大きいほど平らになる）。隣接ドットのコントラストを残すため控えめ。
    static let noiseLevel: CGFloat = 0.012
    /// ノイズ除去後のシャープネス（小さいほどエッジが甘くなる）。
    static let sharpness: CGFloat = 0.5
}
