# Runami-NCM

一个跨平台（**Android / Windows / iOS**）网易云音乐本地加密下载文件（`.ncm`）转换还原工具。采用 **Flutter** 与纯 **Dart + Isolate** 高吞吐并发架构重构，全面引入参考 [FlClash](https://github.com/chen08209/FlClash) 的 **Material 3 Expressive (M3E)** 表现力设计语言。

---

## ✨ 核心亮点与技术特性

### 1. 纯 Dart + Isolate 高性能解密流水线
- **零原生动态库依赖**：摒弃 C++/Rust FFI 重度跨平台交叉编译链，全链路采用纯 Dart 实现 `AES-128-ECB` 密钥解包、`RC4` 音频载荷分块流式解密。
- **Isolate 并发隔离**：解密计算与元数据封装运行在后台 `Isolate` 工作池中，单曲 30MB+ 无损 FLAC 转换耗时仅 ~100ms，UI 满帧响应零卡顿。
- **智能格式识别**：通过解密后前 4 字节魔数（`fLaC`）自动识别输出为标准 FLAC 或 MP3 格式。

### 2. 零内嵌字体与系统已安装字体扫描（FlClash 风格）
- **安装包体积立减 85%+**：彻底剔除内嵌几十兆中文字体包。
- **跨平台系统字体动态扫描**：
  - **Windows**：扫描 `C:\Windows\Fonts` 及 `%LOCALAPPDATA%\Microsoft\Windows\Fonts`，动态识别微软雅黑 UI、思源黑体、霞鹜文楷等已安装字体。
  - **Android**：枚举系统已装字体族并动态注入。
  - **iOS**：通过 MethodChannel 枚举系统 `UIFont.familyNames`（如苹方 PingFang SC、Hiragino Sans 等）。
- **实时预览与 100–900 字重阶梯调节**：可视化字体选择面板，支持实时搜索过滤、样本字形渲染及 Thin (100) 到 Black (900) 的动态字重调节。

### 3. 内置网易云官方 EAPI 直连与歌词/封面匹配
- **无需自建服务端**：客户端直接通过 NetEase 官方加密端点拉取高清专辑封面及双语逐行对齐歌词。
- **标准标签落盘**：
  - **MP3**：写入 `ID3v2.3`（`TIT2` 歌名、`TPE1` 歌手、`TALB` 专辑、`APIC` 封面、`USLT` 歌词）。
  - **FLAC**：构建标准 `VORBIS_COMMENT`（`TITLE`, `ARTIST`, `ALBUM`, `LYRICS`）与 `PICTURE` 块。

### 4. 三端原生专属交互体验
- **Windows 桌面端**：
  - 窗口任意区域文件/文件夹拖拽（Drag & Drop）导入 `.ncm`。
  - 自适应侧边导航栏（NavigationRail）与响应式多列布局。
  - 桌面窗口最小化与系统托盘管理。
- **iOS 移动端**：
  - 开启 `UIFileSharingEnabled` 与 `LSSupportsOpeningDocumentsInPlace`，支持系统「文件 (Files)」App 目录访问。
  - 声明 `.ncm` 文件类型，支持从微信、网盘等第三方 App 通过「分享 / 用其他应用打开」直接导入。
- **Android 移动端**：
  - 保持 SAF（Storage Access Framework）持久化目录授权。
  - 适配 Material 3 动态取色（Monet / Dynamic Color）。

---

## 📱 平台包名与签名一致性

- **Android 命名空间**：`com.example.ncmconverter`
- **Android 应用 ID (applicationId)**：`Akari.Said.YuriBest`
- **iOS 束标识符 (Bundle Identifier)**：`Akari.Said.YuriBest`
- **配置持久化变量**：严格继承原项目 `AppPrefs` 的所有键名（`theme_mode`, `custom_path`, `auto_save`, `enable_lyric`, `enable_cover`, `use_monet_colors`, `system_font_id`, `font_weight` 等）。

---

## 🛠️ GitHub Actions 持续集成与签名方案

本项目在 GitHub Actions 中配置了完善的三端自动化构建与签名流水线：

| 平台 | 构建环境 | 签名方案 | 持久化方式 |
| :--- | :--- | :--- | :--- |
| **Android** | `[self-hosted, android-builder]` (InstaBox) | 沿用原项目私钥签名工作流（`apksigner` + `zipalign`） | GitHub Secrets (`SIGNING_KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_ALIAS`) |
| **Windows** | `windows-latest` | Action 自动生成代码签名证书，并使用 `signtool.exe` 进行数字签名 | `actions/cache@v4` 持久化存储证书，并输出备份制品 |
| **iOS** | `macos-latest` | Action 自动生成代码签名证书与密钥链，为 `.app` 执行 codesign 并打包为 `.ipa` | `actions/cache@v4` 持久化存储证书，并输出备份制品 |

> **注意**：构建产物默认只保存在 GitHub Actions 的 Artifacts 中供下载，切勿自动发布到 GitHub Releases，除非用户明确要求发布 Release。

---

## 📂 工程目录结构

```
Runami NCM/
├── .github/workflows/          # GitHub Actions 自动化构建与三端签名工作流
│   ├── android-ci.yml          # Android 签名构建工作流（保持原项目变量与机制）
│   ├── windows-ci.yml          # Windows 自动化构建、证书自签名与持久化缓存
│   └── ios-ci.yml              # iOS 自动化构建、证书自签名、codesign 与 IPA 打包
├── android/                    # Android 原生平台配置与 Gradle 脚本
│   └── app/build.gradle.kts    # 包名: Akari.Said.YuriBest / com.example.ncmconverter
├── ios/                        # iOS 原生工程与 Info.plist 文件关联配置
├── windows/                    # Windows 桌面 Runner 与 C++ 宿主工程
├── assets/                     # 仅包含说明文档，零内嵌字体包
├── lib/
│   ├── core/
│   │   ├── api/                # 网易云 EAPI / WeAPI 加密及直连客户端
│   │   ├── decrypt/            # 纯 Dart + Isolate NCM 解密核心与模型
│   │   ├── lyric/              # LRC 歌词解析、逐行对齐与模糊相似度计算
│   │   ├── metadata/           # MP3 ID3v2 & FLAC Vorbis/Picture 写入引擎
│   │   ├── theme/              # 系统字体扫描器、M3E 主题引擎与 HSL 色彩
│   │   └── utils/              # AppPrefs（键名不变）、AppLogger、FileUtils
│   ├── l10n/                   # 多语言本地化支持（简中、繁中、英文、日文）
│   ├── state/                  # Riverpod 状态流与并发解密队列调度器
│   ├── ui/                     # 自适应导航架、M3E 仪表盘与设置面板
│   └── main.dart               # 应用主入口
├── pubspec.yaml                # Flutter 项目依赖定义
└── README.md
```

---

## 📄 开源许可

本项目遵循 [GNU General Public License v3.0](LICENSE) 许可协议。
