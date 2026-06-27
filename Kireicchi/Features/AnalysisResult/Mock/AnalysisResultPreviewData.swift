#if DEBUG
import SwiftUI
import SwiftData

enum AnalysisResultPreviewData {

    // MARK: - Analysis

    static let analysis = RoomAnalysis(
        score: 72,
        rank: .b,
        messyPoints: [
            MessyPoint(label: "床の衣類",         priority: 5, bbox: NormalizedRect(x: 0.05, y: 0.55, w: 0.40, h: 0.35)),
            MessyPoint(label: "机の上の書類",     priority: 4, bbox: NormalizedRect(x: 0.55, y: 0.10, w: 0.40, h: 0.30)),
            MessyPoint(label: "本棚の整理",       priority: 3, bbox: nil),
            MessyPoint(label: "窓際のゴミ袋",     priority: 2, bbox: NormalizedRect(x: 0.70, y: 0.60, w: 0.25, h: 0.30)),
            MessyPoint(label: "クッションの散乱", priority: 1, bbox: nil),
        ],
        characterComment: "まあまあきれいだけど、床の衣類が気になるな〜！片付けると気持ちいいよ！"
    )

    // MARK: - Dummy Image

    static var dummyImageData: Data {
        pixelArtRoomImage.pngData() ?? Data()
    }

    private static var pixelArtRoomImage: UIImage {
        let size = CGSize(width: 300, height: 300)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let c = ctx.cgContext

            // 背景（壁）
            c.setFillColor(UIColor(red: 0.88, green: 0.82, blue: 0.74, alpha: 1).cgColor)
            c.fill(CGRect(origin: .zero, size: size))

            // 床
            c.setFillColor(UIColor(red: 0.73, green: 0.60, blue: 0.46, alpha: 1).cgColor)
            c.fill(CGRect(x: 0, y: 190, width: 300, height: 110))

            // 窓
            c.setFillColor(UIColor(red: 0.68, green: 0.85, blue: 0.96, alpha: 1).cgColor)
            c.fill(CGRect(x: 30, y: 30, width: 80, height: 70))
            c.setFillColor(UIColor(red: 0.55, green: 0.45, blue: 0.35, alpha: 1).cgColor)
            c.fill(CGRect(x: 30, y: 30, width: 80, height: 4))
            c.fill(CGRect(x: 30, y: 95, width: 80, height: 4))
            c.fill(CGRect(x: 30, y: 30, width: 4, height: 70))
            c.fill(CGRect(x: 106, y: 30, width: 4, height: 70))
            c.fill(CGRect(x: 70, y: 30, width: 2, height: 70))
            c.fill(CGRect(x: 30, y: 65, width: 80, height: 2))

            // 本棚
            c.setFillColor(UIColor(red: 0.60, green: 0.45, blue: 0.30, alpha: 1).cgColor)
            c.fill(CGRect(x: 185, y: 25, width: 100, height: 130))
            let bookColors: [UIColor] = [
                UIColor(red: 0.85, green: 0.25, blue: 0.25, alpha: 1),
                UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1),
                UIColor(red: 0.25, green: 0.75, blue: 0.40, alpha: 1),
                UIColor(red: 0.95, green: 0.75, blue: 0.20, alpha: 1),
                UIColor(red: 0.70, green: 0.30, blue: 0.80, alpha: 1),
                UIColor(red: 0.85, green: 0.50, blue: 0.20, alpha: 1),
            ]
            for (i, color) in bookColors.enumerated() {
                let x = 190 + i * 15
                c.setFillColor(color.cgColor)
                c.fill(CGRect(x: x, y: 35, width: 12, height: 45))
            }
            for (i, color) in bookColors.reversed().enumerated() {
                let x = 190 + i * 15
                c.setFillColor(color.cgColor)
                c.fill(CGRect(x: x, y: 95, width: 12, height: 55))
            }

            // 机
            c.setFillColor(UIColor(red: 0.75, green: 0.60, blue: 0.42, alpha: 1).cgColor)
            c.fill(CGRect(x: 30, y: 155, width: 140, height: 12))
            c.fill(CGRect(x: 35, y: 167, width: 12, height: 35))
            c.fill(CGRect(x: 150, y: 167, width: 12, height: 35))

            // 机の上の書類（散らかり表現）
            c.setFillColor(UIColor.white.cgColor)
            c.fill(CGRect(x: 45, y: 140, width: 45, height: 16))
            c.fill(CGRect(x: 65, y: 136, width: 45, height: 16))
            c.fill(CGRect(x: 90, y: 143, width: 40, height: 14))

            // 床の衣類（散らかり表現）
            c.setFillColor(UIColor(red: 0.35, green: 0.55, blue: 0.80, alpha: 0.85).cgColor)
            c.fill(CGRect(x: 20, y: 210, width: 70, height: 30))
            c.setFillColor(UIColor(red: 0.85, green: 0.35, blue: 0.35, alpha: 0.85).cgColor)
            c.fill(CGRect(x: 55, y: 225, width: 55, height: 25))

            // ゴミ袋
            c.setFillColor(UIColor(red: 0.25, green: 0.65, blue: 0.25, alpha: 0.8).cgColor)
            c.fill(CGRect(x: 225, y: 185, width: 55, height: 70))
            c.setFillColor(UIColor(red: 0.15, green: 0.50, blue: 0.15, alpha: 1).cgColor)
            c.fill(CGRect(x: 238, y: 180, width: 28, height: 8))
        }
    }

    // MARK: - SwiftData Container

    static func makeContainer() -> ModelContainer {
        let container = try! ModelContainer(
            for: LatestRoomRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let missions = analysis.messyPoints.map { MissionPersisted(from: $0) }
        let missionsData = try? JSONEncoder().encode(missions)
        let imageData = dummyImageData
        container.mainContext.insert(LatestRoomRecord(
            pixelArtImageData: imageData,
            capturedAt: Date(),
            score: analysis.score,
            comment: analysis.characterComment,
            messyPointLabels: missions.map { "\($0.label):\($0.priority)" },
            originalImageData: imageData,
            missionsData: missionsData
        ))
        return container
    }
}
#endif
