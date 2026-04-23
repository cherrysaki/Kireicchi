# CLAUDE.md — きれいっち

## アプリ概要

**アプリ名**: きれいっち  
**プラットフォーム**: iOS（iOS 26以上）  
**コンセプト**: 部屋の写真をAIが解析し、片付けアドバイスを提供しながら、ドット絵化した自分の部屋でキャラクターを育てるタマゴッチ風片付け習慣アプリ

---

## 解決したい課題

- 片付けてもすぐ散らかってしまう人が、継続して部屋を綺麗に保てない
- 片付けを「義務」ではなく「キャラクターのため」という動機に変えることで習慣化を促す

---

## MVP機能一覧

### コア機能（MVP必須）

| 機能 | 概要 |
|------|------|
| 撮影 | カメラで部屋を撮影する |
| AI解析 | OpenAI APIで散らかり度スコア（0〜100）・ランク（A〜E）・片付け優先箇所を返す |
| ドット絵生成 | OpenAI APIで撮影画像をドット絵に変換 |
| キャラクター表示 | ドット絵の部屋の中でキャラクターが生活する |
| キャラクター状態変化 | 部屋スコアに応じてキャラクターが「元気／普通／不調」の3段階で変化 |
| 撮影リマインダー通知 | ユーザーが設定した時刻にローカル通知を送る |
| 設定画面 | 撮影時刻・通知ON/OFFの設定 |
| お片付けミッション | ホーム画面に片付けタスクをリスト表示 |

### スコアリングルール

- スコア（0〜100）: OpenAI APIのレスポンスから取得
- ランク: スコアに基づきアプリ側で自動付与
  - A: 85〜100
  - B: 70〜84
  - C: 50〜69
  - D: 30〜49
  - E: 0〜29

### キャラクター状態ルール

- 元気: スコア 70以上
- 普通: スコア 40〜69
- 不調: スコア 39以下

---

## 将来機能（MVP対象外）

- コイン獲得・使用システム
- 友達訪問機能（お邪魔する）
- キャラクター3種類以上への拡張
- ウィジェット
- Apple Watch文字盤
- Multipeer Connectivity / Firebaseによる友達との通信
- キャラクター成長システム
- 片付けタイマー

---

## 画面構成（ワイヤーフレームより）

```
HomeView
├── 設定ボタン（→ SettingsView）
├── 次の撮影までの時間表示
├── 部屋の散らかり指数（スコア表示）
├── ハートゲージ（キャラクター状態）
├── ドット絵部屋 + キャラクター表示
│   └── 部屋の状態に応じたコメント
├── お片付けミッションリスト
└── カメラボタン（→ CaptureView）

CaptureView
├── カメラプレビュー（アスペクト比 1:1 or 3:4）
├── ズームコントロール
└── 撮影ボタン（→ AnalyzingView）

AnalyzingView（解析待ち）
├── 「解析中...」アニメーション
├── キャラクターアニメーション
└── ステップ表示（準備中 → アップロード中 → AI分析中 → 完了）

AnalysisResultView（解析結果）
├── ランク・スコア表示
├── キャラクターコメント
├── ドット絵画像
├── 汚いポイントのハイライト表示
├── 片付け優先箇所リスト（優先度付き）
└── ホーム画面に戻るボタン

SettingsView
├── 撮影時刻設定（ピッカー → 保存）
├── 通知ON/OFFトグル
└── キャラクターのコメント表示
```

---

## ディレクトリ構成

```
きれいっち/
├── App/
│   ├── KireicchiApp.swift
│   └── AppDependencies.swift          # DIコンテナ
│
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── HomeViewModelProtocol.swift
│   │   └── Mock/
│   │       └── MockHomeViewModel.swift
│   │
│   ├── Capture/
│   │   ├── CaptureView.swift
│   │   ├── CaptureViewModel.swift
│   │   ├── CaptureViewModelProtocol.swift
│   │   └── Mock/
│   │       └── MockCaptureViewModel.swift
│   │
│   ├── Analyzing/
│   │   ├── AnalyzingView.swift
│   │   ├── AnalyzingViewModel.swift
│   │   └── AnalyzingViewModelProtocol.swift
│   │
│   ├── AnalysisResult/
│   │   ├── AnalysisResultView.swift
│   │   ├── AnalysisResultViewModel.swift
│   │   ├── AnalysisResultViewModelProtocol.swift
│   │   └── Mock/
│   │       └── MockAnalysisResultViewModel.swift
│   │
│   └── Settings/
│       ├── SettingsView.swift
│       ├── SettingsViewModel.swift
│       ├── SettingsViewModelProtocol.swift
│       └── Mock/
│           └── MockSettingsViewModel.swift
│
├── Domain/
│   ├── Models/
│   │   ├── RoomAnalysis.swift         # struct: スコア・ランク・片付け箇所
│   │   ├── CleanlinessRank.swift      # enum: A〜E
│   │   ├── CharacterState.swift       # enum: 元気・普通・不調
│   │   ├── Character.swift            # struct: キャラクター定義
│   │   ├── CleanupTask.swift          # struct: ミッションタスク
│   │   └── NotificationSettings.swift # struct: 通知設定
│   │
│   └── UseCases/
│       ├── AnalyzeRoomUseCase.swift
│       ├── AnalyzeRoomUseCaseProtocol.swift
│       ├── GeneratePixelArtUseCase.swift
│       ├── GeneratePixelArtUseCaseProtocol.swift
│       ├── ScheduleNotificationUseCase.swift
│       └── ScheduleNotificationUseCaseProtocol.swift
│
├── Data/
│   ├── API/
│   │   ├── OpenAIClient.swift
│   │   ├── OpenAIClientProtocol.swift
│   │   ├── Mock/
│   │   │   └── MockOpenAIClient.swift
│   │   └── DTOs/
│   │       ├── RoomAnalysisRequest.swift
│   │       ├── RoomAnalysisResponse.swift
│   │       └── PixelArtResponse.swift
│   │
│   └── Persistence/
│       ├── RoomRecordStore.swift      # SwiftData操作
│       ├── RoomRecordStoreProtocol.swift
│       └── Models/
│           └── RoomRecord.swift       # @Model: SwiftData永続化モデル
│
├── Infrastructure/
│   └── Notifications/
│       ├── NotificationScheduler.swift
│       └── NotificationSchedulerProtocol.swift
│
└── SharedUI/
    ├── Components/
    │   ├── CharacterView.swift        # キャラクター表示
    │   ├── PixelRoomView.swift        # ドット絵部屋表示
    │   ├── ScoreBadgeView.swift       # スコア・ランクバッジ
    │   └── CleanupTaskRowView.swift   # ミッション行
    └── Extensions/
        └── Image+PixelArt.swift
```

---

## 技術スタック

| 項目 | 採用技術 |
|------|---------|
| UI | SwiftUI |
| アーキテクチャ | MVVM + UseCases |
| データ永続化 | SwiftData |
| AI解析・ドット絵生成 | OpenAI API（GPT-4o / DALL-E 3） |
| 通知 | UserNotifications（ローカル通知のみ） |
| カメラ | AVFoundation |
| 最小OS | iOS 26 |

---

## アーキテクチャ原則

- **MVVM準拠**: ViewはViewModelのみ参照。ビジネスロジックはUseCaseに切り出す
- **Protocol駆動DI**: ViewModel・UseCase・APIClientはすべてProtocolを定義し、MockをFeature/Mock/以下に配置
- **Fat ViewModel禁止**: API呼び出し・データ変換はUseCaseが担当。ViewModelはUI状態管理のみ
- **ファイル分割**: struct / class / enum / protocol は原則別ファイル
- **SwiftUI Preview必須**: 全Viewに`#Preview`を記述。MockViewModelを使用すること
- **コメント最小化**: 自明なコードにコメント不要。複雑なロジックのみ簡潔に記述
- **常に動く状態を維持**: 未実装部分はMockで代替し、ビルドが通る状態を保つ

---

## OpenAI API利用方針

### 解析エンドポイント（Chat Completions + Vision）

- モデル: `gpt-4o`
- 入力: 撮影画像（base64）
- 出力（JSON形式で指定）:
  ```json
  {
    "score": 65,
    "messy_points": [
      { "label": "床の上の服", "priority": 3 },
      { "label": "机の上の紙", "priority": 2 }
    ],
    "character_comment": "ちょっと散らかってるみたい..."
  }
  ```

### ドット絵生成エンドポイント（Images）

- モデル: `dall-e-3`
- 入力: 撮影画像の説明 or 画像URL
- 出力: ドット絵スタイルの部屋画像

---

## データモデル（SwiftData）

```swift
// RoomRecord.swift
@Model
class RoomRecord {
    var id: UUID
    var capturedAt: Date
    var score: Int
    var rank: String
    var messyPoints: [String]
    var pixelArtImageData: Data?
    var originalImageData: Data?
}
```

---

## キャラクター仕様（MVP）

- 種類: 2種類（固定スプライト素材）
- 状態: 元気 / 普通 / 不調（各キャラクター × 3状態 = 6画像）
- 選択: 初回起動時またはSettingsで選択
- 保存: UserDefaults（selectedCharacterID）

---

## 通知仕様

- ローカル通知のみ（`UNUserNotificationCenter`）
- ユーザーが設定した時刻に毎日繰り返し
- 通知タップ → CaptureViewを開く
- 通知OFF時は通知をすべてキャンセル

---

## 注意事項

- **指示された機能のみ実装する**。追加機能を勝手に実装しない
- **機能開発ごとにセルフレビュー**を実施し、既存機能が壊れていないことを確認する
- **iOS 26の新APIに注意**（Liquid Glass等のUIKit/SwiftUI変更を把握した上でコードを書く）
- OpenAI APIキーは`Secrets.xcconfig`で管理し、ソースコードにハードコードしない
