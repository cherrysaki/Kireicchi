# きれいっち 技術仕様書（発表・ピッチ用）

> このドキュメントは「技術的な工夫・選定理由を口頭で語れる」ことを目的にまとめたものです。
> 各セクションは **何を → なぜその技術で → どう動くか** の順で読めば、そのまま発表のカンペになります。
> （MVPの機能一覧・デザインシステムは別途 `CLAUDE.md` を参照）

---

## 1. 一言で言うと（エレベーターピッチ）

**「部屋を撮ると、AIが散らかり度を採点し、ドット絵化した自分の部屋でキャラクターが反応する“たまごっち風”片付け習慣化アプリ」**

- 片付けを「義務」ではなく **「キャラクターのため」** という動機に変換して習慣化を促す
- コアループ：

  ```
  毎日の通知 → 部屋を撮影 → AI解析(採点+ドット絵) → 片付けミッション → 片付けタイマー → 翌日へ
  ```

- 語りの軸：**「採点して終わり」ではなく、放置するとキャラの機嫌が時間とともに悪化し、最後は家出する** → だから毎日戻ってきたくなる。

---

## 2. 技術スタック早見表

| 領域 | 採用技術 | なぜこれを選んだか（語りポイント） |
|------|----------|-----------------------------------|
| UI | **SwiftUI** | 宣言的UI＋`#Preview`で画面を高速に試作。ドット絵調のデザインシステムも `ViewModifier` で統一 |
| ローカル永続化 | **SwiftData** | サーバ不要で履歴・最新状態を端末内に完結。写真をクラウドに上げない設計と相性が良い |
| 認証・クラウド | **Firebase**（Auth / Firestore / Analytics） | 認証と「軽い設定の同期」だけに用途を限定。バックエンドを自前で持たない |
| AI | **OpenAI API**（GPT-4o Vision / 画像編集 images/edits） | 採点（Vision）とドット絵生成（画像編集）を1つのプロバイダで完結 |
| カメラ | **AVFoundation** | 正方形(1:1)ファインダーで撮影条件を揃え、AI解析の精度・一貫性を確保 |
| 通知 | **UserNotifications**（ローカル通知のみ） | サーバプッシュ不要。設定時刻に毎日リマインド |
| 近接連携 | **MultipeerConnectivity + NearbyInteraction** | サーバを介さず、近くの端末同士でキャラを行き来させる（ともだち訪問） |

- 言語：**Swift 6** / 最小OS：iOS 18+（開発ターゲットは iOS 26 想定）
- 外部DIライブラリなし。Protocol駆動の **手動DI** で軽量に保つ。

---

## 3. アーキテクチャ（語りどころ：保守性とテスト容易性）

**MVVM + UseCase + クリーンアーキテクチャ**の4レイヤ構成。

```
Features        … 画面ごとのView + ViewModel（MVVM）
   ↓ 参照
Domain          … UseCase（業務ロジック）/ Model（値オブジェクト）
   ↓ 参照
Data            … OpenAIClient / SwiftData Store / Firestore Repository
Infrastructure  … Camera / 通知 / Auth / Connectivity（OS連携の低レイヤ）
```

語れる工夫：

- **Protocol駆動 + 全サービスにMock実装**
  → APIキーや実機がなくても、Mockに差し替えて全画面をPreview・動作確認できる。
  （`AppDependencies` のフラグ `useMockConnectivity` で近接連携もモック化可能）
- **Fat ViewModel禁止**：API呼び出し・データ変換は UseCase が担当し、ViewModelはUI状態管理に専念。
- 代表ファイル：`App/AppDependencies.swift`（DIコンテナ）、`Domain/UseCases/*`、`Data/API/OpenAIClient.swift`

---

## 4. AI解析パイプライン（最大の技術的見せ場）

撮影から結果表示までを4段階で処理する。

```
① 前処理   撮影画像を正方形クロップ＋向き正規化   (SharedUI/Extensions/UIImage+Crop.swift)
   ↓
② 採点     GPT-4o Vision に base64画像＋日本語プロンプトを送信
   ↓        → JSONで score / messy_points / character_comment を受領
③ ドット絵  画像編集API(images/edits)へ multipart送信（タイムアウト120秒）
   ↓
④ 保存     結果を SwiftData に保存し、messy_points をミッション化
```

**② 採点レスポンスの構造**（`Data/API/DTOs/RoomAnalysisRequest.swift` / `OpenAIClient.swift`）

```json
{
  "score": 65,                        // 散らかり度スコア 0-100
  "messy_points": [
    { "label": "床の上の服", "priority": 3, "bbox": [x, y, w, h] }
  ],
  "character_comment": "ちょっと散らかってるみたい..."
}
```

語れる工夫：

- **bbox（正規化座標 0–1）で散らかり箇所をハイライト** → 「どこを片付ければいいか」を画像上で指し示せる。
- **プライバシー配慮**：プロンプトで「写る人物は無視する」と明示。さらに **写真はクラウドに送らず端末内に保存**。
- **APIキーはソースに置かない**：`Secrets.xcconfig`（gitignore対象）→ Info.plist 経由で `AppConfig.openAIAPIKey` が読み込む。
- **待ち時間のUX**：解析＋生成は時間がかかるため、AnalyzingView で「準備中→AI解析中→ドット絵変換中→完了」の4段プログレス＋キャラのランニングアニメで体感を緩和。

---

## 5. ゲーム性のロジック（語りどころ：習慣化の仕掛け）

### スコア → ランク → キャラ状態 の変換

- ランク：A(85–100) / B(70–84) / C(50–69) / D(30–49) / E(0–29)（`Domain/Models/CleanlinessRank.swift`）
- キャラ状態：happy / normal / sad / sick（`Domain/Models/CharacterState.swift`）

### 時間経過でキャラの“ごきげん”が減衰（本アプリの肝）

`Domain/Models/Happiness.swift` — スコアが高いほど好調が長持ち、低いほど早く悪化する。

| 撮影時スコア | ごきげんが0になるまで |
|--------------|------------------------|
| 80–100 | 120時間（約5日） |
| 60–79 | 72時間（約3日） |
| 40–59 | 48時間（約2日） |
| 39以下 | 24時間（約1日） |

> 計算式：`現在のごきげん = score − (score ÷ 上限時間) × 経過時間`（0–100にクランプ）

### そのほかの仕掛け

- **7日間撮影しないとキャラが家出**（置き手紙＝okitegami画像を表示）（`Features/Home/HomeView.swift`）
- **1日2回までの撮影制限**（履歴件数で判定。3回目はアラート）
- **次の撮影時刻のカウントダウン**を `TimelineView` で60秒ごとに更新表示

語りの締め：**「採点して終わり」ではなく時間軸でキャラの感情が動くから、ユーザーが戻ってくる。**

---

## 6. データ永続化と同期戦略

| 保存先 | 内容 | 役割 |
|--------|------|------|
| **SwiftData**（端末内） | `LatestRoomRecord`（最新状態・ミッション）/ `RoomHistoryRecord`（履歴・グラフ用） | 写真・解析結果はすべてローカルに留める |
| **Firestore**（クラウド） | `users/{uid}`：通知設定・選択キャラのみ | デバイス間で“軽い設定”だけ同期 |

認証フロー：

```
起動 → 匿名ログイン（即利用可能） → 後から Apple サインインへリンク昇格
```

語れる工夫：**「写真というセンシティブなデータはクラウドに上げず、軽い設定だけ同期する」** という割り切り。匿名ログインで初回の離脱を防ぎ、Apple連携でアカウントを永続化できる。

---

## 7. 発展機能：ともだち訪問（語りどころ：先端API活用）

サーバを介さず、近くの端末同士でキャラの部屋を見せ合う機能。

- **MultipeerConnectivity**：近接端末をローカルP2Pで自動発見・接続し、`FriendVisitMessage`（hello / NIトークン / bye 等）を交換
- **NearbyInteraction（UWB）**：端末間の距離をメートル単位で計測
- **距離による状態遷移**（`Domain/UseCases/FriendVisitCoordinator.swift`）：

  ```
  tracking ──(0.5m未満に近づく)──▶ visiting（訪問中）
  visiting ──(1.5m超に離れる)──▶ tracking
  ```

語れる工夫：**サーバもアカウント連携も不要**で、物理的に近づくだけでキャラが行き来する“その場の体験”を実現。

---

## 8. 想定Q&A（質疑対策）

**Q. コストやレイテンシは？**
A. OpenAIの2エンドポイント（採点・ドット絵生成）を直接呼ぶ構成。生成は重いので120秒のタイムアウトを設定し、4段プログレスUIで体感待ち時間を緩和。1日2回の撮影制限がコストの上限にもなっている。

**Q. APIキーの管理は？**
A. ソースにハードコードせず、`Secrets.xcconfig`（gitignore）→ Info.plist → `AppConfig` 経由で読み込む。リポジトリにはテンプレート（`Secrets.xcconfig.template`）のみ。

**Q. テスト・開発はどう回している？**
A. 全サービスがProtocol定義＋Mock実装を持つ。`AppDependencies` のフラグでモックに切り替えられ、実機・APIキー・実通信なしでもUIを確認できる。

**Q. プライバシーは？**
A. 写真と解析結果は端末内（SwiftData）のみに保存。クラウドには通知設定と選択キャラだけ。AIプロンプトでも写る人物を無視するよう指示。

**Q. 今後の拡張は？**
A. キャラクターの複数種対応、ドット絵生成のオンデバイス化（コスト・速度改善）、ともだち訪問機能の拡張など。

---

## 付録：主要ファイル早見

| トピック | ファイル |
|----------|----------|
| DIコンテナ／起動 | `App/AppDependencies.swift`, `KireicchiApp.swift` |
| AI通信 | `Data/API/OpenAIClient.swift`, `Data/API/DTOs/RoomAnalysisRequest.swift` |
| 画像前処理 | `SharedUI/Extensions/UIImage+Crop.swift` |
| ごきげん減衰 | `Domain/Models/Happiness.swift` |
| ランク／キャラ状態 | `Domain/Models/CleanlinessRank.swift`, `CharacterState.swift` |
| 永続化 | `Data/Persistence/Models/LatestRoomRecord.swift`, `RoomHistoryRecord.swift` |
| 認証・ユーザー | `Infrastructure/Auth/AuthService.swift`, `Data/Firestore/UserRepository.swift` |
| ともだち訪問 | `Domain/UseCases/FriendVisitCoordinator.swift`, `Infrastructure/Connectivity/*` |
| ホーム画面ロジック | `Features/Home/HomeView.swift` |
