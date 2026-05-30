import Foundation

struct KireicchiWidgetSnapshot: Codable {
    let happiness: Int
    let characterState: String
    let latestPixelRoomImageData: Data?
    let lastCapturedAt: Date?
    let isGone: Bool
    let updatedAt: Date
}
