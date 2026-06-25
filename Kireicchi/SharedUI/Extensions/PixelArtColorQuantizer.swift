import Foundation

/// ドット絵化の色量子化。
///
/// RGB のチャンネル独立量子化は色相を壊し無彩色を色付きにしてしまうため、
/// 以下で「元画像の色の印象」を保つ：
/// - 無彩色（低彩度）ピクセルはグレーランプへ分離（グレーはグレーのまま）
/// - 有彩色は Median Cut で作った画像適応パレットへ、CIELAB 上の最近傍でマッピング
enum PixelArtColorQuantizer {

    /// 暗部で無彩色とみなす絶対色差(max-min)の下限（0...255）。
    private static let absChromaFloor = 16.0

    struct RGB {
        var r: Double
        var g: Double
        var b: Double
    }

    /// sRGB 8bit RGBA バッファ（`ptr`）をインプレースで量子化する。
    /// - Parameters:
    ///   - ptr: premultipliedLast(=RGBA) の生バッファ先頭。
    ///   - pixelCount: ピクセル数（width*height）。
    ///   - paletteSize: 有彩色パレットの最大色数。
    ///   - grayLevels: 無彩色グレーランプの段数。
    ///   - satThreshold: これ未満の彩度(HSV S)を無彩色として扱う（0...1）。
    ///   - neutralize: 全体の色かぶり（色温度）をグレーワールドで穏やかに中立化する。
    static func quantize(ptr: UnsafeMutablePointer<UInt8>,
                         pixelCount: Int,
                         paletteSize: Int,
                         grayLevels: Int,
                         satThreshold: Double,
                         neutralize: Bool) {
        let bpp = 4

        // 0. 色かぶりの穏やかな中立化（任意）。グレーワールドで各チャンネルゲインを算出。
        var gainR = 1.0, gainG = 1.0, gainB = 1.0
        if neutralize {
            var sumR = 0.0, sumG = 0.0, sumB = 0.0
            for i in 0..<pixelCount {
                let o = i * bpp
                sumR += Double(ptr[o]); sumG += Double(ptr[o + 1]); sumB += Double(ptr[o + 2])
            }
            let n = Double(max(1, pixelCount))
            let avgR = sumR / n, avgG = sumG / n, avgB = sumB / n
            let gray = (avgR + avgG + avgB) / 3.0
            // 強度を 0.5 に絞り、極端な補正を避けるため 0.85...1.15 にクランプ
            let strength = 0.5
            func gain(_ avg: Double) -> Double {
                guard avg > 1 else { return 1 }
                let g = 1 + (gray / avg - 1) * strength
                return min(1.15, max(0.85, g))
            }
            gainR = gain(avgR); gainG = gain(avgG); gainB = gain(avgB)
        }

        // 1. 中立化を適用しつつ、各ピクセルを無彩色/有彩色に分類
        var isChromatic = [Bool](repeating: false, count: pixelCount)
        var chromaticColors: [RGB] = []
        chromaticColors.reserveCapacity(pixelCount)

        for i in 0..<pixelCount {
            let o = i * bpp
            let r = min(255, Double(ptr[o]) * gainR)
            let g = min(255, Double(ptr[o + 1]) * gainG)
            let b = min(255, Double(ptr[o + 2]) * gainB)
            ptr[o] = UInt8(r); ptr[o + 1] = UInt8(g); ptr[o + 2] = UInt8(b)

            let maxC = max(r, max(g, b))
            let minC = min(r, min(g, b))
            let chroma = maxC - minC
            let sat = maxC <= 0 ? 0 : chroma / maxC
            // 暗部は相対彩度が小さな差で跳ね上がるため、絶対色差の下限も併用して
            // 暗い無彩色（黒ケース等）をグレー扱いに落とす。
            let isAchromatic = chroma < absChromaFloor || sat < satThreshold
            if !isAchromatic {
                isChromatic[i] = true
                chromaticColors.append(RGB(r: r, g: g, b: b))
            }
        }

        // 2. 有彩色パレット（Median Cut）→ Lab 化
        let palette = medianCut(colors: chromaticColors, maxColors: max(1, paletteSize))
        let paletteLab = palette.map { rgbToLab($0) }

        // 3. グレーランプ（白〜薄グレー / 黒は締まったダークグレー、暗部のみ僅かに寒色）
        let grays = grayRamp(levels: max(2, grayLevels))

        // 4. 各ピクセルを置換
        for i in 0..<pixelCount {
            let o = i * bpp
            let r = Double(ptr[o]); let g = Double(ptr[o + 1]); let b = Double(ptr[o + 2])
            let out: RGB
            if isChromatic[i], !paletteLab.isEmpty {
                let lab = rgbToLab(RGB(r: r, g: g, b: b))
                var best = 0
                var bestDist = Double.greatestFiniteMagnitude
                for (j, pl) in paletteLab.enumerated() {
                    let dl = lab.0 - pl.0, da = lab.1 - pl.1, db = lab.2 - pl.2
                    let dist = dl * dl + da * da + db * db
                    if dist < bestDist { bestDist = dist; best = j }
                }
                out = palette[best]
            } else {
                let lum = 0.299 * r + 0.587 * g + 0.114 * b
                out = nearestGray(lum: lum, ramp: grays)
            }
            ptr[o] = UInt8(max(0, min(255, out.r)))
            ptr[o + 1] = UInt8(max(0, min(255, out.g)))
            ptr[o + 2] = UInt8(max(0, min(255, out.b)))
        }
    }

    // MARK: - グレーランプ

    /// 輝度を grayLevels 段に量子化した無彩色列。最暗部のみ青を僅かに足して締める（黒→青黒）。
    /// r,g は輝度のまま保ち、青のみ加算するので中間〜明部は中立グレーを維持する。
    private static func grayRamp(levels: Int) -> [RGB] {
        let span = Double(levels - 1)
        return (0..<levels).map { i in
            let v = Double(i) / span * 255.0
            // 暗端に集中させる（中点で 0 になる）。
            let t = max(0, 1 - Double(i) / span * 2.0)
            let coolness = t * 7.0
            return RGB(r: v, g: v, b: min(255, v + coolness))
        }
    }

    private static func nearestGray(lum: Double, ramp: [RGB]) -> RGB {
        var best = ramp[0]
        var bestDist = Double.greatestFiniteMagnitude
        for gray in ramp {
            // グレーランプの基準輝度との距離で選ぶ
            let gl = 0.299 * gray.r + 0.587 * gray.g + 0.114 * gray.b
            let d = abs(gl - lum)
            if d < bestDist { bestDist = d; best = gray }
        }
        return best
    }

    // MARK: - Median Cut

    private static func medianCut(colors: [RGB], maxColors: Int) -> [RGB] {
        guard !colors.isEmpty else { return [] }
        var boxes: [[RGB]] = [colors]

        while boxes.count < maxColors {
            // 最も長い軸レンジを持つボックスを選んで分割
            guard let (index, axis) = widestBox(boxes) else { break }
            var box = boxes[index]
            box.sort { component($0, axis) < component($1, axis) }
            let mid = box.count / 2
            guard mid > 0, mid < box.count else { break }
            let lower = Array(box[0..<mid])
            let upper = Array(box[mid...])
            boxes[index] = lower
            boxes.append(upper)
        }

        return boxes.compactMap { averageColor($0) }
    }

    /// 分割対象（最長軸レンジのボックス）を返す。要素1以下のボックスは対象外。
    private static func widestBox(_ boxes: [[RGB]]) -> (Int, Int)? {
        var bestIndex = -1
        var bestAxis = 0
        var bestRange = -1.0
        for (i, box) in boxes.enumerated() where box.count > 1 {
            for axis in 0..<3 {
                var lo = Double.greatestFiniteMagnitude
                var hi = -Double.greatestFiniteMagnitude
                for c in box {
                    let v = component(c, axis)
                    if v < lo { lo = v }
                    if v > hi { hi = v }
                }
                let range = hi - lo
                if range > bestRange { bestRange = range; bestIndex = i; bestAxis = axis }
            }
        }
        return bestIndex >= 0 ? (bestIndex, bestAxis) : nil
    }

    private static func component(_ c: RGB, _ axis: Int) -> Double {
        axis == 0 ? c.r : (axis == 1 ? c.g : c.b)
    }

    private static func averageColor(_ box: [RGB]) -> RGB? {
        guard !box.isEmpty else { return nil }
        var r = 0.0, g = 0.0, b = 0.0
        for c in box { r += c.r; g += c.g; b += c.b }
        let n = Double(box.count)
        return RGB(r: r / n, g: g / n, b: b / n)
    }

    // MARK: - sRGB → CIELAB

    /// (L, a, b) を返す。
    private static func rgbToLab(_ c: RGB) -> (Double, Double, Double) {
        func linearize(_ v: Double) -> Double {
            let s = v / 255.0
            return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4)
        }
        let rl = linearize(c.r), gl = linearize(c.g), bl = linearize(c.b)

        // sRGB(D65) → XYZ
        let x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375
        let y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
        let z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041

        // D65 白色点で正規化
        let xn = x / 0.95047, yn = y / 1.0, zn = z / 1.08883
        func f(_ t: Double) -> Double {
            t > 0.008856 ? pow(t, 1.0 / 3.0) : (7.787 * t + 16.0 / 116.0)
        }
        let fx = f(xn), fy = f(yn), fz = f(zn)
        let l = 116.0 * fy - 16.0
        let a = 500.0 * (fx - fy)
        let bb = 200.0 * (fy - fz)
        return (l, a, bb)
    }
}
