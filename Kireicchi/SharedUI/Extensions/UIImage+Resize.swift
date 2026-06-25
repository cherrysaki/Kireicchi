import UIKit

extension UIImage {
    /// 長辺が maxDimension に収まるよう等比縮小する。元が小さい場合はそのまま返す。
    /// draw(in:) を通すため orientation も .up に正規化される。
    func resized(maxDimension: CGFloat) -> UIImage {
        let longSide = max(size.width, size.height)
        guard longSide > maxDimension, longSide > 0 else { return self }

        let scale = maxDimension / longSide
        let newSize = CGSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
