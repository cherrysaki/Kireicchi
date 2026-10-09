import Foundation

struct MissionPersisted: Codable, Hashable, Identifiable {
    let id: String
    let label: String
    let priority: Int
    let bbox: NormalizedRect?
    let estimatedMinutes: Int?  // 片付けの目安分数（任意）。旧データはnil
    var isDone: Bool

    init(id: String, label: String, priority: Int, bbox: NormalizedRect?, estimatedMinutes: Int? = nil, isDone: Bool) {
        self.id = id
        self.label = label
        self.priority = priority
        self.bbox = bbox
        self.estimatedMinutes = estimatedMinutes
        self.isDone = isDone
    }

    init(from messyPoint: MessyPoint, isDone: Bool = false) {
        self.id = messyPoint.id
        self.label = messyPoint.label
        self.priority = messyPoint.priority
        self.bbox = messyPoint.bbox
        self.estimatedMinutes = messyPoint.estimatedMinutes
        self.isDone = isDone
    }
}
