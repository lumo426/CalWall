# CalWall

macOS 菜单栏小工具：用**自定义日程**生成日历壁纸，自动设为桌面背景。

支持日 / 周 / 月 / 年四种壁纸视图，浅色 / 深色 / 蓝色三种外观，以及中英文界面。

**仓库地址：** https://github.com/lumo426/CalWall

**下载安装包：** [GitHub Releases](https://github.com/lumo426/CalWall/releases)（下载 zip → 解压 → 拖入「应用程序」）

---

## 功能

- 菜单栏常驻，点击图标打开控制面板
- **结构化日程**：填写标题 + 选择年/月/日/时/分，无需在文本里手写时间
- 日程同步显示在日 / 周 / 月 / 年壁纸上
- 三种外观：浅色 / 深色 / 蓝色（蓝色模式下可切换白天 / 黑夜）
- **日程字号**：小 / 标准 / 大 / 特大（控制壁纸上日程文字大小）
- 中英文界面切换
- 开机自启、自动刷新间隔、日程导入/导出
- 日视图时间轴：05:00 – 23:00
- 纯本地运行，不读取 Apple 日历，不上传任何数据

---

## 快速使用

1. 打开控制面板 → **自定义日程**
2. 输入**日程内容**（如 `作品集修改`）
3. 在下方选择**年 / 月 / 日 / 时 / 分**
4. 点击 **添加日程** → 壁纸自动更新
5. 若字太小：在 **外观主题** 下方把 **日程字号** 调到「大」或「特大」

切换 **Day / Week / Month / Year** 可预览不同视图的日程显示。

---

## 安装（Release 包）

1. 从 [Releases](https://github.com/lumo426/CalWall/releases) 下载 `CalWall-vX.X.X-macOS.zip`
2. 解压，将 `CalWall.app` 拖入「应用程序」
3. 若提示 **「已损坏，无法打开」**（Gatekeeper 常见误报）：

```bash
xattr -cr "/Applications/CalWall.app"
```

或：**右键** App → **打开** → **打开**

---

## 本地开发与运行

### 环境要求

- macOS 14.0+
- Xcode 16+

### 首次配置

1. 克隆仓库，用 Xcode 打开 `CalWall.xcodeproj`
2. **TARGETS → CalWall → Signing & Capabilities**
3. 勾选 **Automatically manage signing**，选择 Team
4. 如有冲突，修改 **Bundle Identifier**
5. **Run**（⌘R）

### 命令行编译

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme CalWall -configuration Debug -derivedDataPath build/DerivedData build
```

### 设置 App 图标

**Assets.xcassets → AppIcon** 拖入 1024×1024 PNG → Clean Build → Build

---

## 打包与发布

### Release 编译 + zip

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd /path/to/CalWall_Dopamine_Custom

xcodebuild -scheme CalWall -configuration Release \
  -derivedDataPath build/DerivedData build

mkdir -p build/release
ditto -c -k --keepParent \
  build/DerivedData/Build/Products/Release/CalWall.app \
  build/release/CalWall-v1.1.0-macOS.zip
```

> **必须带代码签名编译**，否则用户下载后会提示「已损坏」。

### 上传 GitHub Release

```bash
export https_proxy=http://127.0.0.1:7897   # 如需代理
export http_proxy=http://127.0.0.1:7897

git push origin main

gh release create v1.1.0 build/release/CalWall-v1.1.0-macOS.zip \
  --repo lumo426/CalWall \
  --title "CalWall 1.1.0" \
  --notes "Release notes..."
```

更完整的流程见 **[PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)** §6。

---

## 项目结构

```text
CalWall/
  CalWallApp.swift              # 入口，菜单栏
  ContentView.swift             # 控制面板 UI
  AppState.swift                # 状态与刷新逻辑
  AppLocalization.swift         # 中英文文案
  AppPreferences.swift          # 自动化与备份
  CustomScheduleItem.swift      # 日程模型与存储
  ScheduleDateTimeControls.swift # 日期时间选择器
  WallpaperRenderer.swift       # 壁纸绘制
  WallpaperService.swift        # 设置桌面壁纸
  WallpaperTheme.swift          # 主题与字号
  CalendarEvent.swift           # 事件模型
```

---

## 文档

| 文件 | 用途 |
|---|---|
| [README.md](README.md) | 本文件：功能说明与快速上手 |
| [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) | 架构、发版流程、与 AI 协作方式 |
| [CHANGELOG.md](CHANGELOG.md) | 版本变更记录 |

---

## 常见问题

| 问题 | 处理 |
|---|---|
| 打开提示「已损坏」 | `xattr -cr /Applications/CalWall.app` 或右键打开 |
| 周/月视图日程字太小 | 控制面板 → 日程字号 → 大 / 特大 |
| 终端连不上 GitHub | 设置代理或开 TUN 模式 |
| 菜单栏两个图标 | 先 Quit 旧进程，再开新版 |
| 换了 Bundle Identifier | 相当于新 App，需删旧版 |

---

## License

MIT — 见 [LICENSE](LICENSE)
