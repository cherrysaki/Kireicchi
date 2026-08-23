import Foundation

/// App Group 上のファイルに追記する永続デバッグログ。
/// アプリ本体プロセスと Widget Extension プロセスの両方から同じファイルへ書き込むため、
/// 「どちらのプロセスが・いつ・どんな Snapshot を save/load したか」を時系列で確認できる。
/// Console.app を使わず、ファイルを直接読むことで検証する用途。
enum WidgetDebugLog {
    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: KireicchiWidgetConstants.appGroupID)?
            .appendingPathComponent("widget_debug_log.txt")
    }

    static func append(_ message: String) {
        guard let url = fileURL else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
        let process = ProcessInfo.processInfo.processName
        let line = "\(ts) [\(process)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            handle.write(data)
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func clear() {
        guard let url = fileURL else { return }
        try? Data().write(to: url, options: .atomic)
    }
}
