# PriceMate App Store assets

制作日：2026-10-03。ロケール：日本語。

## 納品物

| フォルダー／ファイル | 用途 |
|---|---|
| iphone-6.5/ | 1242 × 2688 px、縦4枚 |
| ipad-13/ | 2064 × 2752 px、縦4枚 |
| PriceMate-AppStore-ja.zip | 上記8枚のみをまとめた入稿用ZIP |
| raw/ | 装飾前の実画面描画、各端末4枚。入稿ZIPには含めない |
| preview-*.jpg | 全枚を並べた確認用。ストアへの入稿対象ではない |
| index.html | 原寸画像へのリンク付きギャラリー |
| ASO改善提案.md | 調査結果と優先順位 |
| ストア掲載文案.md | タイトル、サブタイトル、キーワード、説明文 |
| manifest.json | 寸法、形式、SHA-256 |

入稿PNGは24bit RGBでアルファチャンネルなし。Appleの現行仕様に記載される寸法を採用。[スクリーンショット仕様](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

## 撮影・制作条件

Windows上のFlutter widget testで、プロジェクトのPriceMateShellと実際の各機能画面を描画し、RepaintBoundaryからPNGを書き出した。実機・iOS Simulatorのスクリーンキャプチャではない。

iPhoneは414 × 896論理pxから3倍、iPadは1032 × 1376論理pxから2倍。iPadはスマートフォン画像の引き伸ばしではなく、iPad幅でレイアウトを再計算している。外枠は汎用的な画面フレームで、特定のApple製品の外観を再現したものではない。

日本語フォントはWindowsの游ゴシック、絵文字はSegoe UI Emojiを使用。iOS実機のシステムフォント・絵文字・OSバーとは異なる。フォントファイルは納品物に含めない。撮影用データは架空の買い物例。Firestore・認証・広告配信には接続していない。広告は未ロード状態、オンボーディングの説明表示は完了済みとしている。日付は撮影日時を使うため、再生成時に変わる。

既存の作業中翻訳を含む現在のプロジェクトを撮影した。公開中の画像とは画面デザインが異なる。**このUIを含む提出予定ビルドと対応させ、iOS実機またはSimulatorで表示を照合してから入稿する。** 現行公開版の撮影済み画像だとみなさない。

## 再生成

プロジェクトのルートで実行する。

```powershell
flutter test test/app_store_capture_test.dart --dart-define=STORE_CAPTURE=true --no-pub --reporter expanded
powershell -ExecutionPolicy Bypass -File deliverables/app-store/package-assets.ps1
```

1つ目は8枚の完成レイアウトと8枚の元画面を出力。2つ目は完成画像のRGB変換、寸法情報・一覧画像・ZIPの生成。必ず順に実行する。必要な日本語・絵文字フォントのパスは生成コード内に記載。

## 検証

- iPhone/iPadの実画面描画・4タブ操作を含む撮影テストに成功。
- 8枚を一覧で目視確認し、ボタン文字と絵文字の欠落を修正。
- 完成PNGの寸法・RGB形式・枚数を確認。
- iOSビルド・実機動作・App Store Connectへのアップロードと審査通過は未検証。
- この作業でアプリ本体の機能変更、ストア公開操作はしていない。
