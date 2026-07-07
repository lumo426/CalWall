# CalWall — 项目上下文

> 给「未来的自己」和 **AI 助手（Cursor）** 看的项目说明书。  
> 公开说明见 [README.md](README.md)，版本历史见 [CHANGELOG.md](CHANGELOG.md)。

---

## 1. 项目是什么

**CalWall** 是一个 macOS **菜单栏应用**（无 Dock 图标）：

1. 用户在控制面板里添加**自定义日程**（标题 + 日期时间）
2. 应用把日程渲染成**日历壁纸 PNG**
3. 自动设为**所有显示器**的桌面背景

- **不**读取 Apple 日历
- **不**联网上传数据
- 数据保存在本机 `UserDefaults`

**仓库：** https://github.com/lumo426/CalWall  
**本地路径：** `/Users/houyixuan/Projects/CalWall_Dopamine_Custom`  
**Bundle ID：** `com.yeseon.CalWall`  
**当前版本：** 1.1.0 (Build 2)

---

## 2. 技术栈

| 项 | 值 |
|---|---|
| 语言 | Swift 5 |
| UI | SwiftUI |
| 壁纸绘制 | AppKit（`NSBitmapImageRep` + `NSGraphicsContext`） |
| 最低系统 | macOS 14.0 |
| IDE | Xcode 16+ |
| 依赖 | 无第三方库 |

---

## 3. 目录与职责

```text
CalWall/
  CalWallApp.swift           # @main 入口，菜单栏 StatusItem
  ContentView.swift          # 控制面板 UI（语言、视图、主题、日程、自动化）
  AppState.swift             # @MainActor 全局状态、刷新逻辑、日程 CRUD
  AppLocalization.swift      # L10n 中英文文案
  AppPreferences.swift       # 开机自启、自动刷新、日程备份 import/export
  CustomScheduleItem.swift   # 日程模型 + CustomScheduleStore + 旧文本迁移解析
  CustomScheduleEntry.swift  # 日程草稿辅助（CustomScheduleDraft）
  ScheduleDateTimeControls.swift  # 年/月/日/时/分 Picker 组件
  CalendarEvent.swift        # 壁纸渲染用的统一事件模型
  WallpaperRenderer.swift    # 核心：绘制日/周/月/年壁纸 PNG
  WallpaperService.swift     # 遍历 NSScreen，调用 Renderer 并 setDesktopImageURL
  WallpaperTheme.swift       # 主题色板、字号档位、UserDefaults 持久化
  Assets.xcassets/           # App 图标
```

### 数据流（简化）

```text
用户输入日程
  → AppState.addScheduleItem()
  → CustomScheduleStore.setItems()  [UserDefaults JSON]
  → AppState.refresh()
  → CustomScheduleStore.events(for: perspective)
  → WallpaperService.updateWallpaper()
  → WallpaperRenderer.render() → PNG 文件
  → NSWorkspace.setDesktopImageURL()
```

### 持久化 Key

| Key | 内容 |
|---|---|
| `CalWall.CustomSchedule.items.v2` | 日程 JSON 数组 |
| `CalWall.CustomSchedule.global` | 旧版纯文本（仅迁移用） |
| `CalWall.ThemeFamily` | light / dark / blue |
| `CalWall.BlueThemeVariant` | light / dark |
| `CalWall.EventFontScale` | small / standard / large / extraLarge |
| `CalWall.AppLanguage` | en / zh-Hans |
| `CalWall.AutoRefreshInterval` | 0 / 15 / 30 / 60 分钟 |

壁纸 PNG 输出目录：`~/Library/Application Support/CalWall/`

---

## 4. 常见改动入口

| 想改什么 | 主要文件 |
|---|---|
| 控制面板 UI | `ContentView.swift` |
| 日程增删改逻辑 | `AppState.swift`, `CustomScheduleItem.swift` |
| 日期时间选择器 | `ScheduleDateTimeControls.swift` |
| 壁纸布局/字号/颜色 | `WallpaperRenderer.swift`, `WallpaperTheme.swift` |
| 中英文文案 | `AppLocalization.swift` |
| 导入导出 | `AppPreferences.swift` → `ScheduleBackupService` |
| 版本号 | `CalWall.xcodeproj/project.pbxproj` → MARKETING_VERSION |

---

## 5. 本地开发流程

```bash
# 1. 打开工程
open CalWall.xcodeproj

# 2. Signing：TARGETS → CalWall → Automatically manage signing → 选 Team

# 3. Run（⌘R）→ 菜单栏出现日历图标 → 点击打开面板

# 4. 命令行编译（可选）
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -scheme CalWall -configuration Debug -derivedDataPath build/DerivedData build
```

**注意：** 若 `xcode-select` 指向 Command Line Tools 而非 Xcode.app，需先：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

---

## 6. 发版流程（GitHub Release + zip）

完整步骤，按顺序执行：

### 6.1 改版本号

编辑 `CalWall.xcodeproj/project.pbxproj`：

- `MARKETING_VERSION` → 如 `1.2`
- `CURRENT_PROJECT_VERSION` → Build 号 +1

同步更新 [CHANGELOG.md](CHANGELOG.md)。

### 6.2 Release 编译（必须带签名）

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
cd /Users/houyixuan/Projects/CalWall_Dopamine_Custom

rm -rf build/DerivedData
xcodebuild -scheme CalWall -configuration Release \
  -derivedDataPath build/DerivedData build
```

**不要**加 `CODE_SIGNING_ALLOWED=NO`，否则用户下载后会遇到「已损坏，无法打开」。

### 6.3 打 zip

```bash
mkdir -p build/release
ditto -c -k --keepParent \
  build/DerivedData/Build/Products/Release/CalWall.app \
  build/release/CalWall-v1.2.0-macOS.zip
```

### 6.4 提交并推送

```bash
# 若终端访问 GitHub 需代理（端口按实际修改）
export https_proxy=http://127.0.0.1:7897
export http_proxy=http://127.0.0.1:7897

git add .
git commit -m "描述本次改动"
git push origin main
```

### 6.5 创建 GitHub Release

```bash
gh release create v1.2.0 build/release/CalWall-v1.2.0-macOS.zip \
  --repo lumo426/CalWall \
  --title "CalWall 1.2.0" \
  --notes "Release notes..."
```

替换已有 zip：`gh release upload v1.1.0 ... --clobber`

### 6.6 用户安装后若提示「已损坏」

```bash
xattr -cr "/Applications/CalWall.app"
```

或右键 → 打开 → 打开。

> 彻底免提示需要 **Developer ID Application** 证书 + Apple 公证（Notarization）。

---

## 7. 与 AI（Cursor）协作流程

本项目多次通过 Cursor Agent 迭代。推荐工作方式如下。

### 7.1 开新对话时

1. **打开本仓库**作为 Cursor 工作区（`CalWall_Dopamine_Custom`）
2. 让 AI 先读 **`PROJECT_CONTEXT.md`**（本文件）和 **`CHANGELOG.md`**
3. 描述需求时尽量**截图 + 说明期望行为**（例如：「周视图日程字太小，要加字号设置」）

### 7.2 提需求的话术模板

```text
【目标】一句话说明要什么
【位置】哪个界面/视图（可附截图）
【现状】现在怎样、哪里不对
【期望】改完后应该怎样
【范围】只改 UI / 只改壁纸 / 要发 Release 吗
```

**示例（本次会话真实案例）：**

| 轮次 | 用户说了什么 | AI 做了什么 |
|---|---|---|
| 1 | 自定义日程不要在文本里写日期时间，下面加选择器 | 重构 `ContentView` + `ScheduleDateTimeControls`，改 `CustomScheduleStore` |
| 2 | 打包到 GitHub Release 更新 zip | 编译 Release、commit、push、`gh release create v1.1.0` |
| 3 | 打开提示「已损坏」 | 发现上次未签名 → 重新带签名编译 → `gh release upload --clobber` |
| 4 | 周视图字号太小，加设置 | 新增 `WallpaperEventFontScale`，改 `WallpaperRenderer` 事件 pill 字号 |
| 5 | 加 README / PROJECT_CONTEXT / CHANGELOG | 写/更新三份文档 |

### 7.3 适合交给 AI 的事

- UI 布局调整、新设置项
- 壁纸渲染逻辑（字号、颜色、布局）
- 日程存储迁移、导入导出
- 中英文文案补充（`AppLocalization.swift`）
- 编译报错排查、`project.pbxproj` 补新 Swift 文件
- 按本文档流程打 Release zip 并上传 GitHub

### 7.4 需要人工确认的事

- **Git push / GitHub Release**（涉及远程发布，可能需代理）
- **Apple 签名 Team / Bundle ID** 变更
- **Developer ID + 公证**（付费开发者账号）
- 是否 **commit**（用户未明确要求时不要自动提交）

### 7.5 AI 改代码时的约定

- 新 Swift 文件需加入 `CalWall.xcodeproj/project.pbxproj` 的 Sources
- 文案走 `L10n`，不要硬编码中英文字符串
- 用户可见设置需 `UserDefaults` 持久化 + `AppState` 的 `@Published` + `onChange` 刷新壁纸
- 改壁纸视觉效果后提醒用户点 **Refresh Wallpaper** 或切换设置触发自动刷新

### 7.6 继续上次工作时

对 AI 说：

```text
继续 CalWall 项目。请先读 PROJECT_CONTEXT.md 和 CHANGELOG.md，
然后帮我 [具体任务]。
```

---

## 8. 已知限制

- Release 包为 **Apple Development** 签名，非 Developer ID，首次打开可能需要 `xattr -cr` 或右键打开
- 仅 **arm64**（Apple Silicon）本机编译；Intel Mac 需单独配置
- `CustomScheduleEntry.swift` 中部分类型与 `CustomScheduleItem.swift` 有重叠，后续可合并清理
- 自动刷新依赖应用进程常驻；退出后不会后台刷新

---

## 9. 相关链接

- [README.md](README.md) — 用户向说明与快速上手
- [CHANGELOG.md](CHANGELOG.md) — 版本变更记录
- [GitHub Releases](https://github.com/lumo426/CalWall/releases)
