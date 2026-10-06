# 追加キャラクターの画像素材

## 生成方法

Codex内蔵の image_gen を使用。背景は透過指定。4列×2行のスプライトシートを8姿に切り出し、既存と同じ命名の7種類のGIFを作成しています。

- character03: はなっち（ピンクの花の妖精）
- character04: ほしっち（黄色の星の妖精）。初案から五芒星の輪郭を強める修正を実施。
- 上段: normal / happy / sad / sick
- 下段: walk / walk_alt / cheer / run

元シートは各フォルダの `character03-sheet.png` / `character04-sheet.png`。512×512のPNGと800×450のGIFは同じシートから再生成できます。

```sh
swift Tools/SliceCharacterSheet.swift DesignAssets/character03/character03-sheet.png DesignAssets/character03 character03
swift Tools/MakeCharacterGIFs.swift DesignAssets/character03 Kireicchi/Assets.xcassets/character03 character03
swift Tools/SliceCharacterSheet.swift DesignAssets/character04/character04-sheet.png DesignAssets/character04 character04
swift Tools/MakeCharacterGIFs.swift DesignAssets/character04 Kireicchi/Assets.xcassets/character04 character04
```

歩行は2姿を交互に切り替え、左右300pxを移動し、端で反転して戻る32フレームです。ホームの既存の待機・歩行切替は変更していません。

## 共通生成プロンプト

```text
Use case: stylized-concept. Asset type: production game sprite sheet with exactly EIGHT full-body poses of ONE new mascot. The supplied images are STYLE references only, not subjects to duplicate. Same cute coarse pixel art, charcoal pixel eyes, coral cheeks, stubby arms and feet, crisp staircase edges, limited pastel palette.
Layout: a wide canvas with EXACTLY 4 equal columns and 2 equal rows, an invisible regular grid. Each of the eight cells has ONE sprite centered with at least 15% transparent padding. No sprite crosses a cell boundary. Equal character size across all cells.
Reading order left-to-right then top-to-bottom:
top row: 1 neutral friendly standing smile; 2 happy with excited sparkling eyes; 3 sad with tears and downturned mouth; 4 sick with half-closed eyes and sweat.
bottom row: 5 walking facing RIGHT, left foot extended forward and right foot back; 6 walking facing RIGHT, opposite stride right foot forward left foot back (clearly different legs and arms, same head/body); 7 cheer with arms raised and joyful face; 8 running facing RIGHT leaning forward with legs spread.
Background: genuine transparent alpha in every cell. No grid lines, no text or labels, no floor, no frames, no watermark, no props, no extras. Match identity, face, palette and proportions across all eight poses. Not 3D, no painterly textures, no antialiasing.
```

## はなっち追加指定

```text
Subject: character03, Hanacchi, a cheerful pale coral-pink FLOWER fairy with five rounded chunky petals around a cream face, small green leaf arms and two green stubby feet. Distinct flower silhouette, pink/cream/sage green palette. Adorable bold readable face like the references.
```

## ほしっち初案追加指定

```text
Subject: character04, Hoshicchi, a warm buttery-yellow five-point STAR fairy, rounded chunky five-point silhouette, tiny gold arms and orange-gold stubby feet, dark readable face with coral cheeks. Pastel yellow/gold palette and one small white pixel highlight. Original star silhouette distinct from flower and droplet.
```

## ほしっち最終修正プロンプト

```text
Edit this eight-pose pixel mascot sprite sheet. CRITICAL requested change: replace the bloated house/diamond-like body in EVERY pose with a immediately unmistakable CLASSIC FIVE-POINT STAR silhouette, like the outline of ⭐. Five long distinct triangular tips (one upward, two sideways and two diagonally downward), with five deep V-shaped inward notches between them. Each inward radius is 42% of outer radius. The two LOWER DIAGONAL STAR POINTS must be long and visible; attach TINY feet below the inner lower body, do not turn these star points into feet or a flat bottom. Tiny arms must not replace the two side tips. This recognizable five-point star outline must remain consistent even in side-facing walking/running poses; use a front/three-quarter face so the star shape stays readable. Yellow/gold coarse pixel art body, black eyes, coral cheeks, white pixel highlight, same face identity and mood order. Maintain exactly 4 columns x2 rows in equal cells. Pose order: neutral, happy, sad, sick; walk right left-foot-forward, walk right right-foot-forward, cheer, run right. Give ample transparent padding (at least 15%) in each cell and same sprite scale. Make the walk legs/arms alternate clearly. Remove all stray floating pixels and sparkles except tears/sweat belonging to mood. Genuine transparent background. No labels, text, grid, border, floor or extras. The star silhouette is the priority over retaining the original body shape. Crisp staircase edges, not blurred.
```
