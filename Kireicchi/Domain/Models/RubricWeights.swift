import Foundation

/// 観点別スコアから総合点を算出するための重み。
struct RubricWeights {
    let floor: Double
    let surfaces: Double
    let clutter: Double
    let storage: Double
    let tidiness: Double

    /// 観点別スコアの重み付き平均を0〜100の整数で返す。
    func composite(from axes: RubricAxes) -> Int {
        let raw = Double(axes.floor) * floor
            + Double(axes.surfaces) * surfaces
            + Double(axes.clutter) * clutter
            + Double(axes.storage) * storage
            + Double(axes.tidiness) * tidiness
        return max(0, min(100, Int(raw.rounded())))
    }
}

/// 将来「評価者の目」ごとに重みを切り替える前提のペルソナ定義。
/// 段階1では `.standard` の1セットのみを使用し、切り替えUIは設けない。
enum EvaluatorPersona: String, CaseIterable {
    case standard

    static let `default`: EvaluatorPersona = .standard

    var weights: RubricWeights {
        switch self {
        case .standard:
            return RubricWeights(floor: 0.30, surfaces: 0.25, clutter: 0.20, storage: 0.15, tidiness: 0.10)
        }
    }
}
