import Foundation

struct CleanupTask: Identifiable, Hashable {
    let id: UUID
    let label: String
    let priority: Int
    var isCompleted: Bool
    
    init(label: String, priority: Int, isCompleted: Bool = false) {
        self.id = UUID()
        self.label = label
        self.priority = priority
        self.isCompleted = isCompleted
    }
}