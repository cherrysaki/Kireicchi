import Foundation
import UIKit

struct RoomAnalysisRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    
    private enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
    }
    
    init(imageData: Data) {
        self.model = "gpt-4o"
        self.maxTokens = 700

        // アップロード時間・トークン削減のため送信前に縮小（bboxは正規化座標なので影響なし）
        let payloadData: Data
        if let resized = UIImage(data: imageData)?.resized(maxDimension: 768),
           let jpeg = resized.jpegData(compressionQuality: 0.8) {
            payloadData = jpeg
        } else {
            payloadData = imageData
        }
        let base64Image = payloadData.base64EncodedString()

        let systemMessage = ChatMessage(
            role: "system",
            content: [
                .text("""
あなたは部屋の片付けアドバイザーです。
送られてきた部屋の画像を見て、以下のJSON形式のみで返答してください。
余分なテキストやmarkdownは絶対に含めないでください。

重要な指示:
- 画像に人物が写っていても無視してください。
- 人物のプライバシーに関する判断は一切行わないでください。
- 部屋・床・家具・物の状態のみを評価してください。
- 人物が写っていることを理由に解析を拒否しないでください。

{
  "score": 0から100の整数（100が完璧に綺麗）,
  "messy_points": [
    {
      "label": "片付けが必要な場所の名前",
      "priority": 1から5の整数,
      "bbox": [x, y, w, h]
    }
  ],
  "character_comment": "キャラクターのひとこと（日本語・20文字以内・かわいい口調）"
}

bbox の仕様:
- 画像の左上=(0,0), 右下=(1,1) の正規化座標。x,y は領域の左上、w,h は幅と高さ。
- 値は必ず 0 以上 1 以下。x+w および y+h は 1 を超えないこと。
- 対象がどこにあるか特定できない場合は bbox フィールドを省略してよい。
""")
            ]
        )
        
        let userMessage = ChatMessage(
            role: "user",
            content: [
                .text("この部屋の画像を解析して、JSON形式で片付け情報を教えてください。"),
                .imageUrl(ImageContent(
                    url: "data:image/jpeg;base64,\(base64Image)",
                    detail: "high"
                ))
            ]
        )
        
        self.messages = [systemMessage, userMessage]
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: [MessageContent]
}

enum MessageContent: Codable {
    case text(String)
    case imageUrl(ImageContent)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageUrl = "image_url"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .imageUrl(let imageContent):
            try container.encode("image_url", forKey: .type)
            try container.encode(imageContent, forKey: .imageUrl)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "text":
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case "image_url":
            let imageContent = try container.decode(ImageContent.self, forKey: .imageUrl)
            self = .imageUrl(imageContent)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown message content type: \(type)")
            )
        }
    }
}

struct ImageContent: Codable {
    let url: String
    let detail: String
}
