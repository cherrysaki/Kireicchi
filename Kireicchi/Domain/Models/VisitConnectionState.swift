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
        case .idle:                    return "まだ探していません"
        case .discovering:             return "友達を探しています..."
        case .connecting(let name):    return "\(name) と接続しています..."
        case .connected:               return "繋がりました!"
        case .tracking:                return "近づいてみよう"
        case .visiting:                return "友達が来ました!"
        case .error(let msg):          return "エラー: \(msg)"
        }
    }
}
