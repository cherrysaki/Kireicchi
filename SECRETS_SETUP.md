# Secrets.xcconfig セットアップ手順

OpenAI API キーをプロジェクトに安全に埋め込むための手順書。各開発環境で一度だけ実施してください。

---

## 前提

- OpenAI のアカウントがあり、API キー（`sk-...` 形式）を発行済みであること
  - 未発行の場合は https://platform.openai.com/api-keys から発行
- Xcode 16 以降 / iOS 26 SDK
- このリポジトリを clone 済み

---

## 仕組み（読み込みフロー）

```
Secrets.xcconfig        ← あなたが実キーを記入するファイル（gitignore 済）
       │
       │ Xcode ビルド時に OPENAI_API_KEY を Build Settings に注入
       ▼
Kireicchi/Info.plist    ← OPENAI_API_KEY = $(OPENAI_API_KEY) で変数展開
       │
       ▼
AppConfig.openAIAPIKey  ← Bundle から Info.plist を読み込みキーを返す
       │
       ▼
OpenAIClient            ← Authorization: Bearer ヘッダに設定してAPIコール
```

関連ファイル:

| ファイル | 役割 |
|---|---|
| `Secrets.xcconfig` | 実 API キー保管（**gitignore済・要各自作成**） |
| `Secrets.xcconfig.template` | テンプレート（空値） |
| `Kireicchi.xcodeproj/project.pbxproj` | `Secrets.xcconfig` を `baseConfigurationReference` として登録済 |
| `Kireicchi/Info.plist:33-34` | `OPENAI_API_KEY = $(OPENAI_API_KEY)` で変数展開 |
| `Kireicchi/Infrastructure/Config/AppConfig.swift:6-23` | 読み込み・検証処理 |
| `.gitignore` | `Secrets.xcconfig` を除外 |

---

## 手順

### 1. Secrets.xcconfig を編集

リポジトリルート（`Kireicchi.xcodeproj` と同じ階層）にある `Secrets.xcconfig` を開き、ダミー値を実キーに置き換える。

**場所**: `/Users/<you>/PersonalProduct/Kireicchi/Secrets.xcconfig`

**編集前（ダミー値）**:
```
OPENAI_API_KEY = REPLACE_WITH_YOUR_API_KEY
```

**編集後**:
```
OPENAI_API_KEY = sk-proj-abc123...（あなたのキー）
```

> **Note**: `=` の前後のスペースは任意。キー末尾に不要なスペース・改行が入らないよう注意。

### 2. Xcode プロジェクト設定の確認（通常はスキップ可）

**このプロジェクトでは既に設定済みです**。念のため確認したい場合のみ以下を実施。

1. Xcode で `Kireicchi.xcodeproj` を開く
2. 左ペインで **プロジェクトルート**（Kireicchi）を選択
3. 中央ペイン上部で **PROJECT > Kireicchi** を選択
4. **Info** タブ → **Configurations** セクションを確認
5. Debug / Release それぞれの行を展開し、`Kireicchi` ターゲットのプルダウンが **Secrets** になっていることを確認（表示名は `Secrets.xcconfig` ファイル名から自動抽出）

未設定の場合のみ、プルダウンから `Secrets` を選択。

### 3. クリーンビルド

ビルド設定が変わるため、キャッシュを消して再ビルドする。

- Xcode メニュー: **Product > Clean Build Folder**（⇧⌘K）
- 続けて **Product > Build**（⌘B）

### 4. 動作確認

アプリをシミュレータまたは実機で起動し、Xcode のコンソールに以下が表示されれば成功:

```
✅ AppConfig: 設定値の検証が完了しました
```

> 現状 `AppConfig.validateConfiguration()` の自動呼び出しは未配線のため、起動だけでは表示されない場合があります。確認したい場合は `KireicchiApp.init()` などで `AppConfig.validateConfiguration()` を一度呼び出してください。

実際に解析機能（撮影 → 解析）を通すと OpenAI への通信が発生します。401 が返る場合はキーの誤記・期限切れを疑ってください。

---

## トラブルシューティング

### `fatalError: OpenAI APIキーが設定されていません。`
- `Secrets.xcconfig` の `OPENAI_API_KEY` が空。値を記入して再ビルド。

### ビルド後もキーが空 / 旧値のまま
- Clean Build Folder（⇧⌘K）を実施していない可能性。必ずクリーン後に再ビルド。
- Xcode の DerivedData が残っていることも。`~/Library/Developer/Xcode/DerivedData/Kireicchi-*` を削除して再ビルド。

### HTTP 401 Unauthorized
- キーのコピペミス（前後の空白・改行）を確認。
- OpenAI ダッシュボードでキーが有効かつ課金設定済みか確認。

### xcconfig に書いた値が反映されない
- `//` を含む値はコメントとして切り捨てられる。OpenAI のキーは通常 `//` を含まないが、別の値を入れる際は注意。
- プロジェクト設定の **Configurations** に `Secrets` が紐付いているか再確認（手順2）。

---

## セキュリティ注意事項

- `Secrets.xcconfig` は **絶対に git commit しない**（`.gitignore` 済だが誤って `-f` で追加しないこと）
- API キーを Slack・Issue・チャットに貼り付けない
- 万が一流出した場合は OpenAI ダッシュボードで即座に revoke し、新キーを発行
- チーム共有はパスワードマネージャ（1Password 等）を使う

---

## 新規メンバー向けクイックスタート

```bash
# 1. リポジトリルートに移動
cd /path/to/Kireicchi

# 2. テンプレートから Secrets.xcconfig をコピー（既に存在する場合はスキップ）
cp Secrets.xcconfig.template Secrets.xcconfig

# 3. 好きなエディタで実キーを記入
open -e Secrets.xcconfig

# 4. Xcode を開いてクリーンビルド
open Kireicchi.xcodeproj
# Xcode で ⇧⌘K → ⌘B
```
