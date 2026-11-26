[English](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_EN.md) | [繁體中文](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_TC.md) | [日本語](https://github.com/Akiyama-25/Runami-NCM/blob/main/README_JA.md)

# Runami-NCM

将网易云音乐加密的 `.ncm` 文件解密为标准 MP3 或 FLAC 格式的跨平台应用（支持 **Android / Windows / iOS**），基于 Flutter 与纯 Dart + Isolate 并发架构打造，完整移植原版 [NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android) 的 UI 与交互体验。

## 功能

- 批量转换，支持单次导入最多 50 个 `.ncm` 文件并自动过滤非 `.ncm` 文件
- 纯 Dart + Isolate 并发解密流水线，零原生动态库依赖，转换过程不阻塞 UI
- 自动写入元数据（标题、艺术家、专辑、封面）
- 自动搜索并嵌入歌词，支持原文与翻译独立开关控制
- 系统文件夹选择器设置导出目录，支持自动保存与手动逐条保存切换
- 桌面端（Windows）支持直接拖拽 `.ncm` 文件到窗口导入；iOS 支持通过系统「文件 (Files)」App 与分享菜单导入
- Material You 动态取色（Android 12+ 等支持动态取色的平台）
- 自定义强调色与背景色（HSL 渐变滑条实时预览）
- Material 3 Expressive (M3E) 风格卡片与响应式网格布局，适配手机、折叠屏、平板与桌面宽屏
- 读取本机系统已安装字体（零内嵌字体包，支持 Android / Windows / iOS 系统字体扫描、搜索、实时预览切换与 100–900 九档字重自定义调节）
- 预见性返回手势与跟手缩放预览过渡（设置页侧滑返回透出底层主页，支持动态圆角卡片与视差缩放）
- 双击返回键退出（Android）
- 内置运行日志查看与导出（支持日志级别与 `.log` / `.txt` / `.md` 格式切换）及 Markdown 使用说明
- 多语言支持：简体中文、繁体中文、English、日本語

## 系统要求

- **Android**：Android 8.0（API 26）及以上（targetSdk 36）
- **Windows**：Windows 10 / 11（x64）
- **iOS**：iOS 13.0 及以上

## 技术栈

- Flutter + Dart（Isolate 并发解密）+ Material 3 (M3E)
- Riverpod + `dynamic_color`
- Dio + PointyCastle（纯 Dart `AES-128-ECB` / `RC4` 解密与网易云 EAPI 直连）
- `file_picker` / `desktop_drop` / `window_manager` / `path_provider`

## 构建

### 本地构建

```bash
git clone https://github.com/Akiyama-25/Runami-NCM.git
cd Runami-NCM
flutter pub get

# Android APK
flutter build apk --release

# Windows x64
flutter build windows --release

# iOS（未签名构建）
flutter build ios --release --no-codesign
```

### GitHub Actions 自动化构建

本项目采用纯 GitHub Actions 托管环境（`ubuntu-latest` / `windows-latest` / `macos-latest`）执行三端自动化构建与持久签名，构建产物自动上传至 Actions Artifacts：

- **Android**（`ubuntu-latest`）：`flutter test` + 构建 Release APK + `zipalign` / `apksigner` 持久签名
- **Windows**（`windows-latest`）：构建 Windows x64 Release + `signtool.exe` 代码签名并打包 ZIP
- **iOS**（`macos-latest`）：构建 iOS Release + `codesign` 签名并打包 IPA

## 歌词功能

歌词自动嵌入功能已内置网易云官方接口直连，开箱即用，无需额外搭建外部云端服务。

1. APP 默认使用内置官方直连 API，无需额外配置即可自动获取并嵌入歌词与封面。
2. 歌词功能开启后，可独立控制是否嵌入「原文歌词」与「翻译歌词」（若同时开启将自动逐行对齐合并）。

> 注：翻译歌词功能仅支持简体中文翻译结果。当 APP 语言不是简体中文时，翻译开关会显示相应提示。

## 参考项目

本项目开发过程中参考了以下项目：

- [Akiyama-25/NCM-Converter-For-Android](https://github.com/Akiyama-25/NCM-Converter-For-Android) — 原版 Android 项目的 UI 设计、交互规范与核心逻辑来源
- [chen08209/FlClash](https://github.com/chen08209/FlClash) — M3E 表现力设计语言与系统已安装字体选择器参考
- [rinchao0721/Melodia](https://github.com/rinchao0721/Melodia) — 提供了客户端内置加密直连网易云官方 API 的架构思路与协议参考
- [Ame-Player](https://github.com/Akiyama-25/Ame-Player) — 客户端内置 NetEase 官方加密直连与构建签名工作流参考
- [NLyric](https://github.com/wwh1004/NLyric) — 歌词匹配策略参考
- [openyyy.com](https://openyyy.com/) — NCM 格式解析参考

## 许可证

本项目基于 [GPL v3](https://github.com/Akiyama-25/Runami-NCM/blob/main/LICENSE) 许可证开源。
