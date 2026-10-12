import UIKit
import ImageIO

final class CachedAnimatedGIF: NSObject {
    let images: [UIImage]
    let duration: TimeInterval

    init(images: [UIImage], duration: TimeInterval) {
        self.images = images
        self.duration = duration
    }
}

final class AnimatedGIFCache: @unchecked Sendable {
    static let shared = AnimatedGIFCache()

    private let cache = NSCache<NSString, CachedAnimatedGIF>()

    private init() {
        cache.countLimit = 24
        cache.totalCostLimit = 96 * 1_024 * 1_024
    }

    func gif(named assetName: String) -> CachedAnimatedGIF? {
        if let cached = cache.object(forKey: assetName as NSString) {
            return cached
        }

        guard let gifData = NSDataAsset(name: assetName)?.data,
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }

        var images: [UIImage] = []
        var frameDelays: [Int] = []

        for index in 0..<CGImageSourceGetCount(source) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            images.append(UIImage(cgImage: cgImage))

            let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any]
            let gifProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let delay = gifProperties?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
                ?? gifProperties?[kCGImagePropertyGIFDelayTime as String] as? Double
                ?? 0.1
            frameDelays.append(max(20, Int((delay * 1_000).rounded())))
        }

        guard !images.isEmpty else { return nil }
        // UIImageView gives array entries equal time. Reuse decoded images to
        // preserve the GIF's short blink frames and longer resting frames.
        let frameStep = max(20, frameDelays.dropFirst().reduce(frameDelays[0], greatestCommonDivisor))
        let playbackImages = zip(images, frameDelays).flatMap { image, delay in
            Array(repeating: image, count: max(1, Int((Double(delay) / Double(frameStep)).rounded())))
        }
        let duration = Double(frameStep * playbackImages.count) / 1_000
        let gif = CachedAnimatedGIF(images: playbackImages, duration: duration)
        let memoryCost = images.reduce(into: 0) { cost, image in
            let pixelWidth = image.size.width * image.scale
            let pixelHeight = image.size.height * image.scale
            cost += Int(pixelWidth * pixelHeight * 4)
        }
        cache.setObject(gif, forKey: assetName as NSString, cost: memoryCost)
        return gif
    }

    private func greatestCommonDivisor(_ lhs: Int, _ rhs: Int) -> Int {
        var a = lhs
        var b = rhs
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return a
    }
}
