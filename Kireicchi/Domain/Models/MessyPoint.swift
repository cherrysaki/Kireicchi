import Foundation

struct NormalizedRect: Hashable, Codable {
    let x: Double
    let y: Double
    let w: Double
    let h: Double

    var isValid: Bool {
        let inRange = (0...1).contains(x) && (0...1).contains(y) && (0...1).contains(w) && (0...1).contains(h)
        return inRange && (x + w) <= 1.01 && (y + h) <= 1.01 && w > 0 && h > 0
    }
}

struct MessyPoint: Hashable, Codable, Identifiable {
    let label: String
    let priority: Int  // 1〜5 (5が最高優先度)
    let bbox: NormalizedRect?

    var id: String { "\(label)|\(priority)" }

    init(label: String, priority: Int, bbox: NormalizedRect? = nil) {
        self.label = label
        self.priority = priority
        self.bbox = bbox
    }

    private enum CodingKeys: String, CodingKey {
        case label
        case priority
        case bbox
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.priority = try container.decode(Int.self, forKey: .priority)
        self.bbox = try Self.decodeBBox(from: container)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(priority, forKey: .priority)
        if let bbox {
            try container.encode([bbox.x, bbox.y, bbox.w, bbox.h], forKey: .bbox)
        }
    }

    private static func decodeBBox(from container: KeyedDecodingContainer<CodingKeys>) throws -> NormalizedRect? {
        guard container.contains(.bbox), try container.decodeNil(forKey: .bbox) == false else {
            return nil
        }
        if let arr = try? container.decode([Double].self, forKey: .bbox), arr.count == 4 {
            let r = NormalizedRect(x: arr[0], y: arr[1], w: arr[2], h: arr[3])
            return r.isValid ? r : nil
        }
        if let r = try? container.decode(NormalizedRect.self, forKey: .bbox) {
            return r.isValid ? r : nil
        }
        return nil
    }
}
