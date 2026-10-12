# おそうじ仲間5種類

初期の白い「きれいっち」と、承認された立ち絵4体をもとに、内蔵画像生成ツールで表情と行動の各コマを生成。
参考にした履歴は「画像からペットを作成」（2026-10-09）。輪郭・顔の一致、異なる手足と表情のコマ、共通倍率・接地位置、透過背景を確認する。

| ID | 名前 | 特徴 |
| --- | --- | --- |
| character01 | きれいっち | 初期の白い子 |
| character02 | もっぷっち | ラベンダー色のモップ耳 |
| character03 | ほうきっち | ピーチ色の体とほうきしっぽ |
| character04 | あわっち | ミント色の体と泡のかんむり |
| character05 | ぽっけっち | 黄色い体と青いポッケ |

白い子のビジュアルは、2026-10-12に指定された `kireicchi_geekten2026.pptx.png` を正とする。
青い輪郭（参照画像から約 `#2B65B3`）、丸い体、きらきらした黒い目、ピンクのほっぺと口を保持。
全28コマの外枠が青であり、黒い外枠に戻っていないことを `character01/outline-validation.json` で検査する。

`references/` に生成時の立ち絵、`manifest.json` にプロンプトと参照画像を保存。
各種類に、4列×4行の表情シートと4列×3行の行動シートがある。

- 表情: normal / happy / sad / sick。各4コマ。
- 行動: walk / cheer / run。各4つのポーズ。walkは往復移動に展開。
- 種類ごとのフォルダ: 7種類の静止PNGとGIF、各ポーズのPNG、選択画面用の正方形portrait GIF、全状態GIF、コンタクトシート。
- `validation.json`: 元画像のポーズ数、抽出範囲、共通倍率、GIFのコマ数・重複・透明度の検査結果。

素材加工にはPillowとNumPyが必要。

```sh
python3 Tools/BuildCharacterAnimations.py DesignAssets/CleaningCharacters
```

白い子だけを修正したときは `--characters character01` を指定できる。全5種類のGIF検査と一覧プレビューは更新する。

この処理は生成済みの画素を抽出・整列・符号化する。キャラクターや表情を手描きで合成しない。
アプリ用のGIFは800×450、選択画面用GIFと静止画像は512×512。全GIFは透過・無限ループ。
各状態は3種類以上の異なるコマを持つことを検査し、接地位置をそろえて切れを防ぐ。

`character01`〜`character04` の保存IDを維持し、`character05` を追加。初回選択と設定画面はいずれも `CharacterType.allCases` を使用。
