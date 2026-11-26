[简体中文](https://github.com/Akiyama-25/Runami-NCM/blob/main/README.md) | [繁體中文](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_TC.md) | [English](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_EN.md)

# Runami-NCM

NetEase Cloud Music で暗号化された `.ncm` ファイルを標準的な MP3 または FLAC 形式に復号するクロスプラットフォームアプリ（**Android / Windows / iOS** 対応）です。Flutter と純粋な Dart + Isolate 並列アーキテクチャで構築され、オリジナルの [NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android) の UI と操作体験を忠実に移植しています。

## 機能

- 一括変換（1 回あたり最大 50 個の `.ncm` ファイルをインポート、`.ncm` 以外のファイルは自動除外）
- 純粋な Dart + Isolate 並列復号パイプライン、ネイティブ動的ライブラリ依存ゼロで UI をブロックしない高速処理
- メタデータ自動書き込み（タイトル、アーティスト、アルバム、カバーアート）
- 歌詞の自動検索・埋め込み、原文と翻訳を独立したスイッチで制御
- システムフォルダ選択器による出力先設定、自動保存・手動保存の切り替えに対応
- デスクトップ（Windows）ではウィンドウへのドラッグ＆ドロップによるインポートに対応、iOS では「ファイル」アプリ連携・共有メニューからのインポートに対応
- Material You ダイナミックカラー（Android 12+ などの対応環境）
- HSL グラデーションスライダーによるアクセントカラー・背景色のリアルタイムカスタマイズ
- Material 3 Expressive (M3E) スタイルのカードとレスポンシブグリッドレイアウト、スマホ・折りたたみ端末・タブレット・デスクトップ対応
- 端末にインストール済みのシステムフォントを読み取り（内蔵フォント容量ゼロ、Android / Windows / iOS でのシステムフォント検索・リアルタイムプレビュー切替および 100〜900 の 9 段階ウェイト調整に対応）
- 予測型バックジェスチャー風の追従スワイプ遷移（設定画面からのスワイプバックで下層ホーム画面を透過プレビュー、動的角丸カード化・パララックス縮小）
- ダブルタップで終了（Android）
- 動作ログビューア＆エクスポート（ログレベル・`.log` / `.txt` / `.md` 形式切替対応）および Markdown 使い方ガイド内蔵
- 多言語対応：簡体字中国語、繁体字中国語、English、日本語

## 動作要件

- **Android**：Android 8.0（API 26）以上（targetSdk 36）
- **Windows**：Windows 10 / 11（x64）
- **iOS**：iOS 13.0 以上

## 技術スタック

- Flutter + Dart（Isolate 並列復号）+ Material 3 (M3E)
- Riverpod + `dynamic_color`
- Dio + PointyCastle（純粋な Dart による `AES-128-ECB` / `RC4` 復号および NetEase EAPI 直接接続）
- `file_picker` / `desktop_drop` / `window_manager` / `path_provider`

## ビルド方法

### ローカルビルド

```bash
git clone https://github.com/Akiyama-25/Runami-NCM.git
cd Runami-NCM
flutter pub get

# Android APK
flutter build apk --release

# Windows x64
flutter build windows --release

# iOS（未署名ビルド）
flutter build ios --release --no-codesign
```

### GitHub Actions 自動ビルド

本プロジェクトは純粋な GitHub Actions ホストランナー（`ubuntu-latest` / `windows-latest` / `macos-latest`）のみで 3 プラットフォームの自動ビルドと永続署名を実行し、成果物を Actions Artifacts にアップロードします：

- **Android**（`ubuntu-latest`）：`flutter test` + Release APK ビルド + `zipalign` / `apksigner` による永続署名
- **Windows**（`windows-latest`）：Windows x64 Release ビルド + `signtool.exe` コード署名および ZIP パッケージ化
- **iOS**（`macos-latest`）：iOS Release ビルド + `codesign` 署名および IPA パッケージ化

## 歌詞機能

歌詞自動埋め込み機能には NetEase 公式直接接続 API が内蔵されており、外部サーバーを構築することなくそのまま利用可能です。

1. アプリはデフォルトで内蔵公式直接接続 API を使用するため、サーバー設定不要で歌詞とカバー画像を取得・埋め込みできます。
2. 歌詞機能を有効にすると、「原文歌詞」と「翻訳歌詞」の埋め込みを個別に制御可能（両方有効時は行ごとに自動結合）。

> 注：翻訳歌詞機能は簡体中国語の翻訳結果のみ対応しています。アプリの言語が簡体中国語以外の場合、翻訳スイッチに対応する注記が表示されます。

## 参考プロジェクト

本プロジェクトの開発にあたり、以下のプロジェクトを参考にしました：

- [Akiyama-25/NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android) — オリジナル Android プロジェクトの UI デザイン、操作仕様およびコアロジックの参考
- [chen08209/FlClash](https://github.com/chen08209/FlClash) — M3E デザイン言語およびシステムフォント選択 UI の参考
- [rinchao0721/Melodia](https://github.com/rinchao0721/Melodia) — クライアント内蔵の暗号化 NetEase 公式直接接続 API の設計方針およびプロトコル参考
- [Ame-Player](https://github.com/Akiyama-25/Ame-Player) — クライアント内蔵 NetEase 暗号化直接接続および署名付きビルドワークフローの参考
- [NLyric](https://github.com/wwh1004/NLyric) — 歌詞マッチング戦略の参考
- [openyyy.com](https://openyyy.com/) — NCM 形式解析の参考

## ライセンス

本プロジェクトは [GPL v3](https://github.com/Akiyama-25/Runami-NCM/blob/main/LICENSE) ライセンスの下でオープンソース化されています。
