#if DEBUG
import SwiftUI

/// App Group 内の widget_debug_log.txt を実機画面上で確認するための一時デバッグ用ビュー。
/// 原因調査用。確認後に SettingsView のリンクごと削除する想定。
struct WidgetLogDebugView: View {
    @State private var logText: String = ""

    private var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: KireicchiWidgetConstants.appGroupID)?
            .appendingPathComponent("widget_debug_log.txt")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button("再読み込み") { reload() }
                Button("クリア") {
                    WidgetDebugLog.clear()
                    reload()
                }
                .foregroundColor(.red)
                Spacer()
            }
            .font(.system(size: 14, weight: .semibold))
            .padding()

            Divider()

            ScrollView {
                Text(logText.isEmpty ? "(ログなし)" : logText)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .navigationTitle("Widgetログ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: reload)
    }

    private func reload() {
        guard let fileURL else {
            logText = "App Group コンテナを取得できません（appGroupID 設定を確認）"
            return
        }
        if let text = try? String(contentsOf: fileURL, encoding: .utf8) {
            // 最新の行を上に出して見やすくする
            logText = text
                .split(separator: "\n", omittingEmptySubsequences: true)
                .reversed()
                .joined(separator: "\n")
        } else {
            logText = "ログファイルがまだありません:\n\(fileURL.path)"
        }
    }
}
#endif
