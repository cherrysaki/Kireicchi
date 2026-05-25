import Foundation

struct MissionPersisted: Codable, Hashable, Identifiable {
    let id: String
    let label: String
    let priority: Int
    let bbox: NormalizedRect?
    var isDone: Bool

    init(id: String, label: String, priority: Int, bbox: NormalizedRect?, isDone: Bool) {
        self.id = id
        self.label = label
        self.priority = priority
        self.bbox = bbox
        self.isDone = isDone
    }

    init(from messyPoint: MessyPoint, isDone: Bool = false) {
        self.id = messyPoint.id
        self.label = messyPoint.label
        self.priority = messyPoint.priority
        self.bbox = messyPoint.bbox
        self.isDone = isDone
    }
}
