import Foundation

/// 片付け評価の観点別スコア（各0〜100、100が最良）。
/// OpenAIはこの観点別スコアを返し、総合点はアプリ側で算出する。
struct RubricAxes: Codable, Hashable {
    let floor: Int      // 床の空き
    let surfaces: Int   // 机・棚などの平面
    let clutter: Int    // 散乱物・放置物の少なさ
    let storage: Int    // 収納の収まり
    let tidiness: Int   // 全体の整然さ

    var isValid: Bool {
        [floor, surfaces, clutter, storage, tidiness].allSatisfy { (0...100).contains($0) }
    }
}
