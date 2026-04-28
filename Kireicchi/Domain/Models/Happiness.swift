import Foundation

struct Happiness {
    static let hoursToZero: Double = 72.0
    static let decayPerHour: Double = 100.0 / hoursToZero
    static let defaultWhenNoRecord: Int = 50

    static func calculate(score: Int, capturedAt: Date, now: Date = .now) -> Int {
        let hours = max(0, now.timeIntervalSince(capturedAt) / 3600)
        let decayed = Double(score) - decayPerHour * hours
        return max(0, min(100, Int(decayed.rounded())))
    }
}
