import Foundation
import os

extension Logger {
    static let widget = Logger(subsystem: "app.kambayashi.yukke.sakai.Kireicchi", category: "widget")
}

struct KireicchiWidgetSnapshot: Codable {
    let happiness: Int
    let characterState: String
    let latestPixelRoomImageData: Data?
    let lastCapturedAt: Date?
    let isGone: Bool
    let updatedAt: Date
}
