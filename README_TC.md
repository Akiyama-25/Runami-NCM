[English](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_EN.md) | [简体中文](https://github.com/Akiyama-25/Runami-NCM/blob/main/README.md) | [日本語](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_JA.md)

# Runami-NCM

將網易雲音樂加密的 `.ncm` 檔案解密為標準 MP3 或 FLAC 格式的跨平台應用（支援 **Android / Windows / iOS**），基於 Flutter 與純 Dart + Isolate 並發架構打造，完整移植原版 [NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android) 的 UI 與互動體驗。

## 功能

- 批次轉換，支援單次匯入最多 50 個 `.ncm` 檔案並自動過濾非 `.ncm` 檔案
- 純 Dart + Isolate 並發解密流水線，零原生動態函式庫依賴，轉換過程不阻塞 UI
- 自動寫入中繼資料（標題、藝術家、專輯、封面）
- 自動搜尋並嵌入歌詞，支援原文與翻譯獨立開關控制
- 系統資料夾選擇器設定輸出目錄，支援自動儲存與手動逐筆儲存切換
- 桌面端（Windows）支援直接拖曳 `.ncm` 檔案至視窗匯入；iOS 支援透過系統「檔案 (Files)」App 與分享選單匯入
- Material You 動態取色（Android 12+ 等支援動態取色的平台）
- 自訂強調色與背景色（HSL 漸層滑桿即時預覽）
- Material 3 Expressive (M3E) 風格卡片與響應式格線佈局，適配手機、摺疊螢幕、平板與桌面寬螢幕
- 讀取本機系統已安裝字型（零內嵌字型包，支援 Android / Windows / iOS 系統字型掃描、搜尋、即時預覽切換與 100–900 九檔字重自訂調節）
- 預見性返回手勢與跟手縮放預覽過渡（設定頁側滑返回透出底層主頁，支援動態圓角卡片與視差縮放）
- 雙擊返回鍵退出（Android）
- 內建執行日誌檢視與匯出（支援日誌層級與 `.log` / `.txt` / `.md` 格式切換）及 Markdown 使用說明
- 多語言支援：簡體中文、繁體中文、English、日本語

## 系統需求

- **Android**：Android 8.0（API 26）及以上（targetSdk 36）
- **Windows**：Windows 10 / 11（x64）
- **iOS**：iOS 13.0 及以上

## 技術棧

- Flutter + Dart（Isolate 並發解密）+ Material 3 (M3E)
- Riverpod + `dynamic_color`
- Dio + PointyCastle（純 Dart `AES-128-ECB` / `RC4` 解密與網易雲 EAPI 直連）
- `file_picker` / `desktop_drop` / `window_manager` / `path_provider`

## 建置

### 本機建置

```bash
git clone https://github.com/Akiyama-25/Runami-NCM.git
cd Runami-NCM
flutter pub get

# Android APK
flutter build apk --release

# Windows x64
flutter build windows --release

# iOS（未簽署建置）
flutter build ios --release --no-codesign
```

### GitHub Actions 自動化建置

本專案採用純 GitHub Actions 託管環境（`ubuntu-latest` / `windows-latest` / `macos-latest`）執行三端自動化建置與持久簽署，建置產物自動上傳至 Actions Artifacts：

- **Android**（`ubuntu-latest`）：`flutter test` + 建置 Release APK + `zipalign` / `apksigner` 持久簽署
- **Windows**（`windows-latest`）：建置 Windows x64 Release + `signtool.exe` 程式碼簽署並打包 ZIP
- **iOS**（`macos-latest`）：建置 iOS Release + `codesign` 簽署並打包 IPA

## 歌詞功能

歌詞自動嵌入功能已內建網易雲官方介面直連，開箱即用，無需額外架設外部雲端服務。

1. APP 預設使用內建官方直連 API，無需額外設定即可自動取得並嵌入歌詞與封面。
2. 歌詞功能開啟後，可獨立控制是否嵌入「原文歌詞」與「翻譯歌詞」（若同時開啟將自動逐行對齊合併）。

> 註：翻譯歌詞功能僅支援簡體中文翻譯結果。當 APP 語言不是簡體中文時，翻譯開關會顯示相應提示。

## 參考專案

本專案開發過程中參考了以下專案：

- [Akiyama-25/NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android) — 原版 Android 專案的 UI 設計、互動規範與核心邏輯來源
- [chen08209/FlClash](https://github.com/chen08209/FlClash) — M3E 表現力設計語言與系統已安裝字型選擇器參考
- [rinchao0721/Melodia](https://github.com/rinchao0721/Melodia) — 提供了客戶端內建加密直連網易雲官方 API 的架構思路與協定參考
- [Ame-Player](https://github.com/Akiyama-25/Ame-Player) — 客戶端內建 NetEase 官方加密直連與建置簽名工作流程參考
- [NLyric](https://github.com/wwh1004/NLyric) — 歌詞比對策略參考
- [openyyy.com](https://openyyy.com/) — NCM 格式解析參考

## 授權條款

本專案基於 [GPL v3](https://github.com/Akiyama-25/Runami-NCM/blob/main/LICENSE) 授權條款開源。
