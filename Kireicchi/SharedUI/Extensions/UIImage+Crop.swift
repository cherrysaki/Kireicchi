import UIKit

extension UIImage {
    /// 正規化 bbox からクロップ。bbox が nil または無効なら self を返す。
    func cropped(normalized rect: NormalizedRect?, padding: CGFloat = 0.08) -> UIImage {
        guard let rect, rect.isValid else { return self }

        let normalized = self.normalizedOrientation()
        guard let cg = normalized.cgImage else { return self }

        let imgW = CGFloat(cg.width)
        let imgH = CGFloat(cg.height)

        var x = CGFloat(rect.x)
        var y = CGFloat(rect.y)
        var w = CGFloat(rect.w)
        var h = CGFloat(rect.h)

        // 極小領域は最小 20% に拡大
        let minSide: CGFloat = 0.20
        if w < minSide {
            x = max(0, x - (minSide - w) / 2)
            w = minSide
        }
        if h < minSide {
            y = max(0, y - (minSide - h) / 2)
            h = minSide
        }

        // padding を周囲に足す
        x -= padding
        y -= padding
        w += padding * 2
        h += padding * 2

        // クランプ
        x = max(0, min(1, x))
        y = max(0, min(1, y))
        w = max(0.01, min(1 - x, w))
        h = max(0.01, min(1 - y, h))

        let cropRect = CGRect(x: x * imgW, y: y * imgH, width: w * imgW, height: h * imgH).integral
        guard let cropped = cg.cropping(to: cropRect) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    /// 中央正方形クロップ。短辺に揃えて中央を切り出す。orientation も .up に正規化。
    func croppedToSquare() -> UIImage {
        let normalized = self.normalizedOrientation()
        guard let cg = normalized.cgImage else { return normalized }
        let side = min(cg.width, cg.height)
        let x = (cg.width - side) / 2
        let y = (cg.height - side) / 2
        let rect = CGRect(x: x, y: y, width: side, height: side)
        guard let cropped = cg.cropping(to: rect) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    /// プレビュー (.resizeAspectFill) 上のガイド枠（画面幅いっぱいの中央正方形）に
    /// 一致する中央正方形をクロップする。
    /// - Parameter viewportAspect: プレビュー表示領域の幅 / 高さ（縦画面では < 1）。
    ///
    /// aspectFill ではプレビューが画面全体を覆うようにスケールされるため、
    /// 画面に映っている範囲は元画像の中央 `min(imgW, imgH * viewportAspect)` 四方となる。
    /// この値を一辺とした中央正方形を切り出すことで、ガイド枠の中身と一致させる。
    func croppedToViewfinder(viewportAspect: CGFloat) -> UIImage {
        guard viewportAspect > 0 else { return croppedToSquare() }

        let normalized = self.normalizedOrientation()
        guard let cg = normalized.cgImage else { return normalized }

        let imgW = CGFloat(cg.width)
        let imgH = CGFloat(cg.height)

        let side = min(imgW, imgH * viewportAspect).rounded()
        let x = ((imgW - side) / 2).rounded()
        let y = ((imgH - side) / 2).rounded()
        let rect = CGRect(x: x, y: y, width: side, height: side)

        guard let cropped = cg.cropping(to: rect) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    /// imageOrientation を .up に正規化した UIImage を返す。
    private func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
