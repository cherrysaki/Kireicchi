import Foundation

enum VisitConnectionState: Equatable, Sendable {
    case idle
    case discovering
    case connecting(peerName: String)
    case connected             // hello 交換済み、NI セットアップ前
    case tracking              // NI 開始済み・距離測定中(訪問判定はせず)
    case visiting              // 距離が近い → 双方の部屋に互いのキャラ
    case error(String)

    var isActive: Bool {
        switch self {
        case .idle, .error:
            return false
        default:
            return true
        }
    }

    var headlineText: String {
        switch self {
        case .idle:                    return "まだ さがしていません"
        case .discovering:             return "ともだちを さがして います..."
        case .connecting(let name):    return "\(name) と つないで います..."
        case .connected:               return "つながりました!"
        case .tracking:                return "ちかづいて みよう"
        case .visiting:                return "ともだちが きました!"
        case .error(let msg):          return "エラー: \(msg)"
        }
    }
}
