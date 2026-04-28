import Foundation

struct MessyPoint: Hashable, Codable {
    let label: String
    let priority: Int  // 1〜5 (5が最高優先度)
}