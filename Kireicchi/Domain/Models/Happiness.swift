import Foundation

struct Happiness {
    static let defaultWhenNoRecord: Int = 50

    static func hoursToZero(for score: Int) -> Double {
        switch score {
        case 80...100: return 120.0
        case 60...79:  return 72.0
        case 40...59:  return 48.0
        default:       return 24.0  // 39以下
        }
    }

    static func calculate(score: Int, capturedAt: Date, now: Date = .now) -> Int {
        let hours = max(0, now.timeIntervalSince(capturedAt) / 3600)
        let limit = hoursToZero(for: score)
        let decayPerHour = Double(score) / limit
        let decayed = Double(score) - decayPerHour * hours
        return max(0, min(100, Int(decayed.rounded())))
    }
}
