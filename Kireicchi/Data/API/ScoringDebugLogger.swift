#if DEBUG
import Foundation

/// 採点の検証用ログ（DEBUGビルドのみ）。
/// 端末内のApplication Supportにxxxx.jsonlとして1解析1行で追記する。
/// プライバシー方針維持のため画像は保存せず、外部送信も一切行わない。
enum ScoringDebugLogger {
    private static let fileName = "scoring_debug_log.jsonl"

    static func log(axes: RubricAxes,
                    weights: RubricWeights,
                    persona: EvaluatorPersona,
                    finalScore: Int) {
        guard let dir = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return }
        let url = dir.appendingPathComponent(fileName)

        let entry: [String: Any] = [
            "at": ISO8601DateFormatter().string(from: Date()),
            "model": "gpt-4o",
            "temperature": 0,
            "persona": persona.rawValue,
            "axes": [
                "floor": axes.floor,
                "surfaces": axes.surfaces,
                "clutter": axes.clutter,
                "storage": axes.storage,
                "tidiness": axes.tidiness
            ],
            "weights": [
                "floor": weights.floor,
                "surfaces": weights.surfaces,
                "clutter": weights.clutter,
                "storage": weights.storage,
                "tidiness": weights.tidiness
            ],
            "finalScore": finalScore
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: entry),
              var line = String(data: data, encoding: .utf8) else { return }
        line += "\n"
        guard let lineData = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(lineData)
        } else {
            try? lineData.write(to: url)
        }
    }
}
#endif
