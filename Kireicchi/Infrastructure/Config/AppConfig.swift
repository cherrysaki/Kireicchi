import Foundation

struct AppConfig {
    
    /// OpenAI APIキーをInfo.plistから読み込む
    static var openAIAPIKey: String {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["OPENAI_API_KEY"] as? String,
              !apiKey.isEmpty else {
            fatalError("""
            OpenAI APIキーが設定されていません。
            
            以下の手順で設定してください：
            1. Secrets.xcconfig ファイルを開く
            2. OPENAI_API_KEY = your_api_key_here の形式で実際のAPIキーを設定
            3. プロジェクトをクリーンビルド
            
            注意: Secrets.xcconfigはgit管理されていないため、各環境で個別に設定が必要です。
            """)
        }
        return apiKey
    }
    
    /// 設定値の検証
    static func validateConfiguration() {
        // APIキーの存在確認（アクセスすることで検証）
        _ = openAIAPIKey
        
        print("✅ AppConfig: 設定値の検証が完了しました")
    }
}