import Foundation
import UIKit

struct RoomAnalysisRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    let temperature: Double
    let seed: Int
    let responseFormat: ResponseFormat

    private enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
        case seed
        case responseFormat = "response_format"
    }

    struct ResponseFormat: Codable {
        let type: String
    }

    init(imageData: Data) {
        self.model = "gpt-4o"
        // 観点別スコア＋目安時間でトークンが増えるため上限を引き上げる
        self.maxTokens = 1200
        // 再現性を優先し温度0。seedで更に揺れを抑える（best-effort）。
        self.temperature = 0
        self.seed = 7
        // JSONオブジェクトを強制し、パース失敗の揺れを減らす
        self.responseFormat = ResponseFormat(type: "json_object")

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
あなたは片付けの評価に特化したアドバイザーです。
送られてきた部屋の画像を、以下の採点ルーブリックに従って観点ごとに採点し、
指定のJSON形式のみで返答してください。余分なテキストやmarkdownは一切含めないでください。

【重要な指示】
- 画像に人物が写っていても無視してください。人物に関する判断は一切行わないでください。
- 部屋・床・家具・物の状態のみを評価してください。人物を理由に解析を拒否しないでください。
- 推測ではなく、画像内で実際に見えている事実にもとづいて採点してください。見えない部分を減点理由にしないでください。

【採点ルーブリック】各観点を0〜100の整数で採点します（100が最良）。
- floor（床の空き）: 床に物がどれだけ無いか。0〜30=足の踏み場が少なく散乱 / 40〜60=一部に物があるが動線は確保 / 70〜100=床にほぼ物がない。
- surfaces（机・棚などの平面）: 平面の上がどれだけ片付いているか。0〜30=平面が物で埋まる / 40〜60=半分程度 / 70〜100=ほぼ片付いている。
- clutter（散乱物・放置物）: 衣類・ゴミ・紙などの放置の少なさ。0〜30=多数放置 / 40〜60=数点 / 70〜100=ほぼ無い。
- storage（収納の収まり）: 物が収納に収まっているか。0〜30=扉や箱から溢れている / 40〜60=一部はみ出し / 70〜100=きちんと収納。
- tidiness（全体の整然さ）: 全体の見た目の整い。0〜30=雑然 / 40〜60=普通 / 70〜100=整って見える。

【出力JSON】以下の形式のみ。総合点は出力しないでください（アプリ側で算出します）。
{
  "axes": { "floor": 0〜100, "surfaces": 0〜100, "clutter": 0〜100, "storage": 0〜100, "tidiness": 0〜100 },
  "messy_points": [
    { "label": "片付けが必要な場所の名前", "priority": 1〜5の整数, "bbox": [x, y, w, h], "estimated_minutes": 1〜30の整数 }
  ],
  "character_comment": "キャラクターのひとこと（日本語・20文字以内・かわいい口調）"
}

【各フィールドの仕様】
- priority: 1〜5の整数。5が最も優先して片付けるべき場所。
- estimated_minutes: その場所を片付けるのにかかる目安の分数（1〜30の整数）。
- bbox: 画像の左上=(0,0), 右下=(1,1) の正規化座標。x,y は領域の左上、w,h は幅と高さ。値は必ず 0 以上 1 以下で、x+w および y+h は 1 を超えないこと。場所を特定できない場合は bbox フィールドを省略してよい。
- messy_points は優先度が高い順に最大5件程度。きれいで指摘が無い場合は空配列 [] にしてください。
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
