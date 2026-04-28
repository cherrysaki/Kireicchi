import SwiftUI

struct ErrorDetailView: View {
    let errorMessage: String
    let rawResponse: String?
    let apiKeyPrefix: String?
    let onCopy: () -> Void
    let onBack: () -> Void
    let onRetry: () -> Void
    
    @State private var showingFullResponse = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // エラータイトル
                HStack {
                    Text("❌")
                        .font(.title)
                    Text("エラーが発生しました")
                        .font(.title2)
                        .bold()
                }
                .padding(.horizontal)
                
                // エラー詳細
                VStack(alignment: .leading, spacing: 8) {
                    Text("エラー詳細:")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)
                
                // APIキー情報（認証エラーの場合）
                if let apiKeyPrefix = apiKeyPrefix {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("認証情報:")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("APIキー: \(apiKeyPrefix)...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal)
                }
                
                // 生レスポンス（JSONデコードエラーの場合）
                if let rawResponse = rawResponse {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("APIレスポンス（生データ）:")
                                .font(.headline)
                                .foregroundColor(.blue)
                            Spacer()
                            Button(showingFullResponse ? "縮小" : "展開") {
                                showingFullResponse.toggle()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        if showingFullResponse {
                            ScrollView {
                                Text(rawResponse)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .textSelection(.enabled)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                    .frame(maxHeight: 200)
                            }
                            
                            Button("レスポンスをコピー") {
                                onCopy()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                        } else {
                            Text(String(rawResponse.prefix(100)) + (rawResponse.count > 100 ? "..." : ""))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // アクションボタン
                HStack(spacing: 12) {
                    Button("戻る") {
                        onBack()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Button("再試行") {
                        onRetry()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
    }
}

#Preview {
    ErrorDetailView(
        errorMessage: "JSONデコードエラー: The data couldn't be read because it isn't in the correct format.",
        rawResponse: """
        {
          "error": {
            "message": "Invalid JSON structure",
            "type": "invalid_request_error",
            "param": null,
            "code": null
          }
        }
        """,
        apiKeyPrefix: "sk-proj-ab",
        onCopy: {
            print("Copy tapped")
        },
        onBack: {
            print("Back tapped")
        },
        onRetry: {
            print("Retry tapped")
        }
    )
}