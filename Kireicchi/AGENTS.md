# AGENTS.md — きれいっち

最終確認: 2026-10-09。現在のソースコード・Xcode設定に基づく開発ガイド。
本書内のパスは、特記がなければリポジトリルート（`Kireicchi.xcodeproj` のある階層）からの相対パス。

## アプリ概要と実装済み機能

部屋の写真をAIが採点し、片付けミッションを提示するiPhone向け習慣化アプリ。
端末内でドット絵化した部屋にキャラクターを表示し、清潔さと時間経過をキャラクターの機嫌に反映する。

- 初回導線: 世界観紹介 → オーナー登録 → キャラクター選択 → チュートリアル → ホーム。
- 撮影・解析: カメラ撮影 → AI解析とローカル画像変換 → 結果・領域付きミッション表示。
- ホーム: 最新の部屋、スコア、幸福度、未完了ミッション、撮影案内、履歴への導線。
- 履歴: 過去の解析記録一覧と詳細。片付けタイマーは開始・一時停止・リセットに対応（初期値5分）。
- キャラクター: 4種類、4段階の機嫌、歩行・応援・走行アニメーション、家出と卵から迎え直す演出。
- 友達訪問: MultipeerConnectivityで端末を接続し、NearbyInteractionで距離を測定。
- 認証・設定: Firebase匿名認証、Appleアカウント連携、Firestoreによるユーザー情報・設定保存。
- 通知: 設定UI・権限要求・通知予約用の部品は存在するが、予約処理への接続は未完了（後述）。

コイン、ウィジェット、Apple Watch文字盤、キャラクターの成長・進化は現行の完成機能として扱わない。
`CharacterFormID` の拡張余地があることと、成長機能が実装済みであることを混同しない。

## 技術構成・開発環境

| 項目 | 現在の構成 |
|------|------------|
| UI | SwiftUI、一部UIKit / WebKit |
| 設計 | MVVM + UseCaseを基本とする手動DI。View内で状態・永続化を扱う画面もある |
| ローカル保存 | SwiftData、UserDefaults / AppStorage |
| クラウド | Firebase Auth / Firestore / Analytics（Swift Package Manager） |
| AI解析 | OpenAI Chat Completions、コード上の指定モデルは `gpt-4o` |
| ドット絵 | Core Graphicsによる端末内の縮小・減色 |
| OS連携 | AVFoundation、UserNotifications、MultipeerConnectivity、NearbyInteraction |
| 対象端末 | iPhone（`TARGETED_DEVICE_FAMILY = 1`） |
| 最低対応OS | アプリターゲットのDebug / Releaseはともに **iOS 18.6** |
| Swift設定 | `SWIFT_VERSION = 5.0`、既定のActor分離は `MainActor` |

プロジェクトレベルのDeployment Targetは26.0だが、アプリターゲットが18.6で上書きしている。
「iOS 26専用」「Swift 6言語モード」と記載しない。新APIを導入する場合はターゲットの最低OSとの互換性を確認する。
SwiftコンパイラのバージョンとSwift言語モードは別物として扱う。

### セットアップとビルド

1. `Kireicchi.xcodeproj` をXcodeで開き、SPM依存関係を解決する。
2. ルートの `Secrets.xcconfig` がなければ `Secrets.xcconfig.template` から作成し、`OPENAI_API_KEY` を設定する。既存ファイルを上書きしない。
3. 対象Firebaseプロジェクトの `Kireicchi/GoogleService-Info.plist` を用意する。実機では署名と必要な権限も確認する。
4. `Kireicchi` スキームでビルドする。CLIでのシミュレータ向けビルド例:

```sh
xcodebuild -project Kireicchi.xcodeproj -scheme Kireicchi \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/kireicchi-derived-data CODE_SIGNING_ALLOWED=NO build
```

この例は実機署名や実サービスの接続確認を代替しない。
セットアップの補足は [SECRETS_SETUP.md](../SECRETS_SETUP.md) を参照する。ただし同資料の環境要件や固定パス例は現行設定と照合する。
APIキーは `Secrets.xcconfig → Info.plist → AppConfig → OpenAIClient` の順に読み込まれる。
`AppConfig.validateConfiguration()` は起動時に自動実行されていないため、起動ログだけで設定済みと判断しない。

## コードの配置と依存関係

```text
Kireicchi/
├── KireicchiApp.swift       # Firebase初期化、AppDependencies、SwiftDataコンテナ
├── ContentView.swift       # RootViewへの入口
├── App/                    # AppDependencies: 起動・認証・設定更新・サービス生成
├── Navigation/             # RootView、NavigationRouter
├── Features/
│   ├── WorldviewOnboarding/ # 世界観紹介、オーナー登録、キャラクター選択
│   ├── Onboarding/         # UsernameRegistrationView
│   ├── Tutorial/
│   ├── Home/
│   ├── Capture/
│   ├── Analyzing/
│   ├── AnalysisResult/
│   ├── CleanupTimer/
│   ├── History/
│   ├── FriendVisit/
│   ├── RunawayRecovery/
│   └── Settings/
├── Domain/
│   ├── Models/             # 解析・ミッション・幸福度・キャラクター・ユーザー等
│   └── UseCases/           # 解析、画像変換、認証、通知、友達訪問等
├── Data/
│   ├── API/                # OpenAIClient、DTO、Mock
│   ├── Persistence/        # 最新記録・履歴のStoreとSwiftDataモデル
│   └── Firestore/          # UserRepository、Protocol、Mock
├── Infrastructure/         # Auth、Camera、Config、Connectivity、Notifications
├── SharedUI/               # DesignSystem、共通部品、画像処理
└── Assets.xcassets/        # キャラクターGIF、背景など
```

素材原画はルートの `DesignAssets/`、素材加工スクリプトは `Tools/` にある。

- `RootView` が初回導線と通常のNavigationStackを切り替える。通常の遷移は `NavigationRouter.Route` に集約する。
- `Analyzing`、`CleanupTimer`、`History`、`FriendVisit` にはViewModel / Protocol / Mockがある。
- `Home`、`Capture`、`AnalysisResult`、`Settings` はView内の状態管理を含む。存在しないViewModelを前提に作業しない。
- `AppDependencies` は認証・設定同期・サービス生成を担当するが、全サービスをMockへ一括切替するコンテナではない。
- `useMockConnectivity` は近接通信の切替専用。`currentOpenAIClient()` は常に実際の `OpenAIClient` を返す。

## 撮影・解析・保存の流れ

1. `CaptureView` と `CameraController` で撮影し、正方形クロップ等の前処理を行う。
2. `AnalyzingViewModel` が `AnalyzeRoomUseCase` と `GeneratePixelArtUseCase` を `async let` で並列実行する。
3. 解析結果から優先度の高い順にミッションを作り、最新記録と履歴を保存する。
4. 画像データ・ドット絵・解析結果を渡して `AnalysisResultView` へ遷移する。失敗時にはエラー表示と再試行導線がある。

### AI解析

`Kireicchi/Data/API/DTOs/RoomAnalysisRequest.swift` がリクエストの正。
画像は最大辺768px・JPEG品質0.8を目標に変換し、base64で送信する。
`/v1/chat/completions` にモデル `gpt-4o`、`max_tokens = 700` を指定する。
JSON出力はプロンプトで要求しており、レスポンスをパーサーで読み取る。

```json
{
  "score": 65,
  "messy_points": [
    { "label": "床の上の服", "priority": 3, "bbox": [0.1, 0.5, 0.3, 0.2] }
  ],
  "character_comment": "少しずつ片付けよう！"
}
```

- スコアは0〜100で、**高いほど綺麗**。ランクはアプリ側で計算する。
- 優先度は1〜5で、高いほど優先。`bbox` は省略可能な `[x, y, width, height]` の正規化座標（左上原点）。
- パーサーはスコア・優先度の範囲とコメント20文字以内を検証する。座標の扱いは `MessyPoint` / `NormalizedRect` も確認する。

### ローカルのドット絵変換

`GeneratePixelArtUseCase` が `UIImage+PixelArt.swift` と `PixelArtColorQuantizer.swift` を使い、PNGデータを返す。
既定値は `gridSize = 128`、`paletteSize = 18`、`grayLevels = 6`、`satThreshold = 0.12`、`neutralize = false`。
表示はピクセルをぼかさない `.interpolation(.none)` を基本とする。

`OpenAIClient.generatePixelArt` と画像編集API用DTOは残っているが、現在の解析画面のドット絵生成経路では使用しない。

### データ保存の役割

| 保存先 | 内容・注意点 |
|--------|-------------|
| SwiftData: `LatestRoomRecord` | 最新のドット絵、元画像、撮影日時、スコア、コメント、ミッション。Storeで原則1件に保つ |
| SwiftData: `RoomHistoryRecord` | 撮影ごとの履歴。ランク、ドット絵、コメント、ミッションを保存。元画像のフィールドはない |
| `MissionPersisted` | ミッションID・ラベル・優先度・領域・完了状態をCodableで表現し、`missionsData` にJSON保存 |
| Firestore: `users/{uid}` | ユーザー情報、認証プロバイダ、選択キャラクター、通知設定 |
| UserDefaults / AppStorage | 初回導線の完了フラグ、`selectedCharacterID`、`isInRunawayState` など |

最新記録の `messyPointLabels` は旧形式との互換用。既存データを考慮せずに削除しない。
ホーム・結果画面でのミッション完了は `LatestRoomRecordStore.updateMission` を通じて最新記録を更新する。履歴への自動反映を前提にしない。
画像はローカル保存されるが、解析用の写真はOpenAIへ送信される。「写真を外部送信しない」と記載しない。

## スコア・キャラクター・家出

### ランクと機嫌

`CleanlinessRank.fromScore` のランク境界は A: 85〜100、B: 70〜84、C: 50〜69、D: 30〜49、E: 0〜29。

キャラクターは `CharacterType` の4種類:
`character01`（きれいっち）、`character02`（しずくっち）、`character03`（はなっち）、`character04`（ほしっち）。

| 機嫌 | `CharacterMood.fromScore` | `CharacterMood.fromHappiness` |
|------|---------------------------|-------------------------------|
| happy / 元気 | 80〜100 | 75〜100 |
| normal / 普通 | 60〜79 | 50〜74 |
| sad / 不調 | 40〜59 | 25〜49 |
| sick / 病気 | 0〜39 | 0〜24 |

ホームの機嫌は撮影時スコアを直接使わず、`Happiness.calculate` で計算した幸福度から決まる。
幸福度は撮影時のスコアから線形に減衰する。0になるまでの時間はスコア80以上:120時間、60〜79:72時間、40〜59:48時間、39以下:24時間。
記録がない場合、ホームのキャラクターはhappy、ハートゲージ用の既定幸福度は50。
`CharacterState` は `CharacterMood` の非推奨typealiasであり、新規コードは `CharacterMood` を使う。

### 撮影制限と家出

- ホームの撮影導線は当日の `RoomHistoryRecord` 件数が2件未満の場合のみ利用できる。これは履歴件数に基づくUI制限であり、シャッターを押した回数やAPI側の制限ではない。
- ホーム表示時、最新記録からCalendar上で7日以上経過すると `isInRunawayState` を立てる。
- 復帰導線は手紙 → 卵を3回タップ → 誕生演出 → ホーム。復帰操作は家出フラグを解除するが、撮影日時は更新しない。
- 設定画面のデバッグ表示には「5日」、家出用のダミー日時には「6日前」が残っている。通常判定の正は `HomeView.detectRunaway` の7日。復帰後の再判定も含め、変更時は実際の動作を確認する。

### 素材とアニメーション

`CharacterPresentation` は種類・形態・機嫌・行動を保持し、`CharacterAssetCatalog` がGIFのData Asset名を解決する。
行動は `idle / walk / cheer / run`。idleでは機嫌のサフィックスを使う。
基本形の命名は `character02_happy`、拡張形態は `{characterID}_{formID}_{suffix}`。

解決順は指定形態 → 同じキャラクターの基本形・指定状態 → 同キャラクターのnormal → character01の指定状態 → character01のnormal。
表示は `CharacterView`、`AnimatedGIFView`、`AnimatedGIFCache`、`CharacterPlaybackMode` を再利用する。
素材加工は `Tools/SliceCharacterSheet.swift` と `Tools/MakeCharacterGIFs.swift` を参照し、実行前に引数と出力先を確認する。
具体例は [character02の素材説明](../DesignAssets/character02/README.md) にある。

## 認証・近接通信・通知

- 起動時にFirebaseを初期化し、`AppDependencies.bootstrap()` が既存セッションを再利用、または匿名サインインしてユーザー文書を作成・取得する。
- Appleサインインは既存Firebaseユーザーへのアカウント連携。キャラクター選択はローカル設定とFirestoreを同期する。
- `FriendVisitCoordinator` はP2P接続で名前・キャラクター・NIトークンを交換する。追跡中に0.5m未満で訪問状態へ入り、訪問中に1.5m超で追跡状態へ戻る。
- 近接通信のUI確認には `MockPeerSession` / `MockNearbyDistanceTracker` を利用できる。実際の距離計測は対応する実機2台で確認する。
- 通知設定の既定値は19:00・有効。チュートリアルで通知権限を要求する。
- `ScheduleNotificationUseCase` / `NotificationScheduler` は毎日繰り返す予約に対応するが、設定保存からUseCaseを呼ぶ処理は接続されていない。現状の設定保存はFirestoreへの更新。
- 通知タップからCaptureへの遷移処理も未実装。通知OFF時の予約解除を含め、設定UIだけを見て動作済みと判断しない。
- スケジューラのキャンセル対象は `kireicchi.daily-photo-reminder` の予約のみ。

## UI・実装方針

### デザインの正

`Kireicchi/SharedUI/DesignSystem.swift` を参照し、既存トークンとModifierを再利用する。

| 用途 | 値 |
|------|----|
| primary / メインアクセント | `#A9DFF9` |
| primaryDark・textPrimary | `#4C3E3C` |
| secondary | `#FFC6D9` |
| secondaryDark | `#C2627E` |
| accent / starYellow | `#FFE497` |
| accentWarm | `#FF9F5E` |
| background / surface | `#FFF9EF` / `#FFFFFF` |
| フォント | カスタムフォント `CP-period` |
| pixelLarge / Medium / Small | 52 / 28 / 17pt |

ピクセル調の枠や影は既存の `.pixelSquareCard` 等を参照する。旧資料のピンクprimaryやroundedシステムフォントをそのまま採用しない。

### 変更時の原則

- 指示された機能・修正に集中し、無関係な機能追加や全体リファクタリングをしない。
- 新規のAPI処理や業務ロジックはUseCase / Service / Storeへ分離し、注入可能な依存関係と必要なProtocol・Mockを用意する。
- ViewModelはUI状態と処理の調整を中心とし、既存Viewの直接参照を「全画面MVVM化済み」と扱わない。
- 型は原則別ファイル。自明なコメントは増やさず、非自明な制約や理由を残す。
- 新規・変更Viewには適切な `#Preview` を用意する。必要なEnvironmentObjectとSwiftDataモデルを渡し、Previewから実APIを呼ばないよう依存を確認する。
- 現状のPreviewには実サービスを生成する箇所がある。特に `AnalyzingView` の既定初期化は実OpenAIクライアントを使うため、Previewがあるだけでオフライン動作可能と判断しない。
- 既存のユーザー変更と保存データを保持し、機能変更ごとにセルフレビューする。未実装の依存には適切なMockを利用し、ビルド可能な状態を保つ。
- APIキーをコード・文書・ログへ追加しない。`Secrets.xcconfig` と `GoogleService-Info.plist` はgitignore対象であり、強制追加しない。既存エラー表示・ログを共有するときもキーの一部や応答内容を確認する。

## 変更内容に応じた検証

現在のXcodeプロジェクトにはテストターゲットがない。存在しないテストコマンドを案内したり、未実施の検証を成功扱いにしたりしない。

- コード・リソース変更: 対象スキームのビルドと、変更した画面のPreviewまたは実行確認。
- 解析・保存: 成功、失敗と再試行、bboxあり・なし、最新記録と履歴、ミッション完了、再起動後の復元。
- スコア・キャラクター: ランクと2種類の機嫌判定の境界値、時間減衰、記録なし、当日履歴0/1/2件、7日前後の家出判定と復帰後。
- 素材・表示: 4種類のキャラクター、4状態と各行動、欠けた素材のフォールバック、GIF表示と画面遷移。
- 認証・通信・通知: Mockで確認できる範囲と実サービス・実機が必要な範囲を分ける。通知を接続する変更では、許可・拒否・ON/OFF・時刻変更・タップ遷移を確認する。
- 文書のみの変更: パス・型・数値・機能の接続状況をソースと照合し、`git diff --check` と変更範囲の確認を行う。ビルドや実API呼び出しは不要。

[TECH_SPEC.md](TECH_SPEC.md) は発表用の説明資料で、画像生成APIや言語設定などに古い記載がある。
文書同士で食い違う場合は実装・プロジェクト設定を確認し、現在の事実と今後の方針を区別して更新する。
