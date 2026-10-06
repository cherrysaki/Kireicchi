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
        var totalDuration: TimeInterval = 0

        for index in 0..<CGImageSourceGetCount(source) {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            images.append(UIImage(cgImage: cgImage))

            if let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil),
               let gifProperties = (frameProperties as NSDictionary)[kCGImagePropertyGIFDictionary] as? [String: Any],
               let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double {
                totalDuration += delayTime
            } else {
                totalDuration += 0.1
            }
        }

        guard !images.isEmpty else { return nil }
        let gif = CachedAnimatedGIF(images: images, duration: max(totalDuration, 0.1))
        let memoryCost = images.reduce(into: 0) { cost, image in
            let pixelWidth = image.size.width * image.scale
            let pixelHeight = image.size.height * image.scale
            cost += Int(pixelWidth * pixelHeight * 4)
        }
        cache.setObject(gif, forKey: assetName as NSString, cost: memoryCost)
        return gif
    }
}
