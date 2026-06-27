import Foundation

/// 家出からの復帰フローの各段階
enum RunawayRecoveryPhase: Hashable {
    case letter   // 手紙画面
    case egg      // 卵画面（タップで孵化）
    case birth    // 誕生演出
}
