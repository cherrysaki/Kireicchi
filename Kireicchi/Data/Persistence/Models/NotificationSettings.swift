import Foundation
import SwiftData

@Model
final class NotificationSettings {
    var hour: Int
    var minute: Int
    var isEnabled: Bool

    init(hour: Int = 19, minute: Int = 0, isEnabled: Bool = true) {
        self.hour = hour
        self.minute = minute
        self.isEnabled = isEnabled
    }
}
