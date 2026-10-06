# character02（しずくっち）

2026-10-06 に ImageGen の image-to-image モードで作成した、2体目のキャラクター原画です。`character01` の静止画を画風の参照にし、輪郭は別物になるように「ミント色のしずく／泡の妖精」として設計しています。

## 生成プロンプト

共通指定:

> 2D iOS cleaning game のプロダクション用ピクセルアート。基準画像のミント色のしずく型シルエット、配色、粗い正方形ピクセル、ハイライト、短い手足、比率、顔の描き方を維持する。1体のみを中央に全身表示し、透明背景と十分な余白を設ける。アンチエイリアス、滑らかなベクター線、3D、文字、ロゴ、透かし、枠、床、風景は禁止。

状態ごとの追加指定:

- `normal`: 正面向きで親しみのある笑顔。
- `happy`: 大きな笑顔、輝く目、上向きの手、左右に小さな黄色の輝き。
- `sad`: 下向きの口と眉、左右の目に涙、下げた手。
- `sick`: 半分閉じた目、波形の口、汗、少し彩度を落とした影。
- `walk`: `walk` と `walk_alt` の反対足を出した2ポーズを交互に表示。右向きに横切ったあと画像を反転し、左向きに戻る往復歩行。
- `cheer`: 両手を上げたジャンプ、大きな笑顔、小さな黄色の輝き。
- `run`: 画面右へ前傾して走る姿、腕振り、後方に小さな水色の速度ピクセル。

## GIF生成

原画PNGからアプリ用の800×450透過GIFを作る処理は `Tools/MakeCharacterGIFs.swift` にあります。各状態の絵そのものは変更せず、数ピクセルの上下・左右移動を付けています。

```sh
xcrun swift -module-cache-path /tmp/kireicchi-swift-module-cache \
  Tools/MakeCharacterGIFs.swift \
  DesignAssets/character02 \
  Kireicchi/Assets.xcassets/character02
```
