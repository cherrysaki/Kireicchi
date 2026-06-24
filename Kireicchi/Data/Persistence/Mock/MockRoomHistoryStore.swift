import Foundation

@MainActor
struct MockRoomHistoryStore: RoomHistoryStoreProtocol {
    func save(_ record: RoomHistoryRecord) throws {}

    func fetchAll() throws -> [RoomHistoryRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // capturedAt を「N日前の hh:mm」で作る
        func makeDate(dayOffset: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        // (何日前, [(時, 分, スコア)])
        // ・2件の日（朝→夜で改善）と1件だけの日を混在
        // ・約3週間分 → 週モードのバケットも複数できる
        let schedule: [(day: Int, entries: [(hour: Int, minute: Int, score: Int)])] = [
            (0,  [(9, 0, 48), (20, 0, 86)]),   // 今日:   D→A（大きく改善）
            (1,  [(10, 0, 62), (21, 0, 78)]),  // 昨日:   C→B
            (2,  [(19, 0, 70)]),               // 2日前:  B のみ
            (3,  [(8, 0, 35), (22, 0, 65)]),   // 3日前:  D→C
            (4,  [(9, 30, 55)]),               // 4日前:  C のみ
            (5,  [(8, 30, 40), (20, 30, 88)]), // 5日前:  D→A
            (6,  [(21, 0, 72)]),               // 6日前:  B のみ
            (7,  [(9, 0, 50), (19, 30, 75)]),  // 7日前:  C→B
            (8,  [(8, 0, 30), (20, 0, 60)]),   // 8日前:  E→C
            (9,  [(9, 0, 90)]),                // 9日前:  A のみ
            (10, [(8, 0, 45), (21, 0, 82)]),   // 10日前: D→B
            (11, [(19, 0, 58)]),               // 11日前: C のみ
            (12, [(9, 0, 38), (20, 0, 70)]),   // 12日前: D→B
            (13, [(10, 0, 66), (22, 0, 84)]),  // 13日前: C→B
            (14, [(8, 30, 52)]),               // 14日前: C のみ
            (15, [(9, 0, 33), (20, 0, 78)]),   // 15日前: D→B
            (16, [(21, 0, 80)]),               // 16日前: B のみ
            (17, [(8, 0, 47), (19, 0, 90)]),   // 17日前: D→A
            (18, [(9, 0, 60), (20, 0, 72)]),   // 18日前: C→B
            (19, [(8, 0, 25)]),                // 19日前: E のみ
            (20, [(9, 0, 55), (21, 0, 85)])    // 20日前: C→A
        ]

        return schedule.flatMap { item in
            item.entries.map { entry in
                RoomHistoryRecord(
                    capturedAt: makeDate(dayOffset: item.day, hour: entry.hour, minute: entry.minute),
                    score: entry.score,
                    rank: CleanlinessRank.fromScore(entry.score).rawValue,
                    pixelArtImageData: nil
                )
            }
        }
    }
}
