# Codemagicで日本語・英語対応を確認する

## 今回の修正

- Runner/Info.plistにCFBundleLocalizationsのja/enを宣言。
- XcodeのknownRegionsにjaを追加。Base/enと開発言語enは維持。
- ja.lprojとen.lprojにInfoPlist.stringsを追加し、XcodeのResourcesに登録。XML形式の文字列辞書で、追加ツールは不要。
- 日本語のアプリ表示名は「プライスメイト」、英語は「PriceMate」。カメラ・写真・トラッキング許可の説明も言語別に用意。
- Runnerの最終ビルド工程「Verify iOS localizations」が、完成した.appの宣言と両言語のリソースを検査。不足時はビルドを失敗させる。署名済みファイルは書き換えない。

この検証はXcodeプロジェクトに組み込まれているので、既存のCodemagicのFlutter workflow editor／YAMLいずれでも、通常のRunnerビルド時に実行される。Python 3が利用可能なmacOSビルド環境を使用する。署名やFirebase、既存のビルド引数を変更する必要はない。

## 次回Codemagicビルド

1. この変更をリポジトリにコミット・プッシュし、そのコミットで既存のiOSワークフローを実行する。
2. 通常どおりApp Store Connectで未使用のビルド番号を指定する。
3. ログの「Verify iOS localizations」で `PASS iOS localizations: ja, en` を確認する。
4. IPA／アーカイブを最終検証するには、workflow editorのPost-buildに以下を追加する。YAML運用なら既存のビルドスクリプト直後、公開処理より前のscriptsステップに同じ内容を置く。プロジェクトがサブフォルダーにある場合はcd先を変更する。

```bash
#!/bin/bash
set -euo pipefail
cd "$CM_BUILD_DIR"
shopt -s nullglob
outputs=(build/ios/archive/*.xcarchive build/ios/ipa/*.ipa)
if [ ${#outputs[@]} -eq 0 ]; then
  echo "error: No iOS archive or IPA found; check the workflow output path."
  exit 1
fi
for output in "${outputs[@]}"; do
  python3 scripts/verify_ios_localizations.py "$output"
done
```

出力先が標準と異なる既存ワークフローではoutputsのパスを実際の出力先に合わせる。生成物がない場合に成功扱いにしない。Post-buildの追加はCodemagic管理画面へのアクセスが必要なため、この作業では未設定。ビルド内の.app検証はリポジトリの変更のみで有効になる。

## Macなしで最終IPAを検証

CodemagicからIPAをダウンロード後、Windowsのプロジェクトルートで実行する。

```powershell
python scripts/verify_ios_localizations.py "C:/path/to/PriceMate.ipa"
```

ZIPを展開せず、トップレベルのアプリのInfo.plistとja/enのInfoPlist.stringsを検証する。XML・バイナリplist両方に対応。

ソースのみの確認：

```powershell
python scripts/verify_ios_localizations.py ios/Runner --source
```

## 公開後の確認

TestFlightで端末／アプリの言語を日本語・英語に切り替え、表示名と権限説明を確認する。Flutter内の言語選択とは別に、OSの権限説明はiOS側の言語設定に従う。許可済みの場合は同じダイアログが再表示されないことに注意。

新ビルドをApp Store Connectにアップロード・処理後、対応言語が日本語・英語になっているか確認する。公開中のページはソース修正だけでは更新されない。ストアの商品名・説明文のローカライズは別途App Store Connectで設定する。

この環境ではiOSビルド、Codemagicでの実行、実際のアーカイブは未検証。ソース検証と検証スクリプトの正常・異常ケースをWindowsで確認済み。

参考：[Appleの言語判定](https://developer.apple.com/library/archive/qa/qa1828/_index.html)、[InfoPlist.strings](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html)、[Codemagicのカスタムステップ](https://docs.codemagic.io/flutter-configuration/custom-scripts/)
