# CalWall

[English](#english) · [中文](#中文)

---

## English

**CalWall** is a privacy-first macOS menu bar app that turns your schedule into a calendar wallpaper. Your plans stay visible on the desktop, while a compact menu bar panel lets you check what is next without leaving your current app.

**Repository:** https://github.com/lumo426/CalWall  
**Download:** [GitHub Releases](https://github.com/lumo426/CalWall/releases)

### Highlights

- **Quick menu bar schedule**: see the next event and today's agenda from any app
- **Calendar wallpaper**: Day, Week, Month, and Year views
- **Structured schedule entry**: title, date, time, and all-day events
- **Quick add** from the menu bar, with full schedule management in a separate window
- Light, dark, and blue themes with adjustable event text size
- English and Simplified Chinese interface
- Launch at login, automatic wallpaper refresh, and JSON import/export
- Privacy-first: no account, no cloud upload, and no Apple Calendar access
- Local anonymous validation report export; schedule titles and dates are never included

### Who it is for

CalWall works best for Mac users who:

- have several important schedules to remember;
- prefer a stable work desktop;
- want passive reminders when returning to the desktop;
- also need a fast way to check the next event from the menu bar.

It is intentionally not designed as a wallpaper collection or a replacement for a full collaborative calendar.

### Quick start

1. Open CalWall from the menu bar.
2. Enter a title and choose a date and time in **Quick add**.
3. Add the schedule; CalWall generates and applies the wallpaper automatically.
4. Use the menu bar panel to check **Up next** and today's schedule at any time.
5. Open **Settings** to change the wallpaper view, theme, text size, automation, or backups.

### Installation

1. Download the latest `CalWall-vX.X.X-macOS.zip` from [Releases](https://github.com/lumo426/CalWall/releases).
2. Unzip it and drag `CalWall.app` into **Applications**.
3. If macOS reports that the app is damaged, run:

```bash
xattr -cr "/Applications/CalWall.app"
```

Alternatively, right-click the app and choose **Open**.

### Development

Requirements:

- macOS 14.0+
- Xcode 16+
- Apple Silicon for the provided release build

Open `CalWall.xcodeproj`, configure **Signing & Capabilities**, and run with `⌘R`.

Command-line build:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -scheme CalWall -configuration Debug \
  -derivedDataPath build/DerivedData build
```

### Project structure

```text
CalWall/
  CalWallApp.swift               # App entry and scenes
  QuickScheduleView.swift        # Menu bar quick schedule panel
  ContentView.swift              # Full settings and schedule management
  AppState.swift                 # State, refresh, and schedule actions
  AppLocalization.swift          # English and Chinese strings
  AppPreferences.swift           # Automation, backup, local validation
  CustomScheduleItem.swift       # Schedule model and persistence
  ScheduleDateTimeControls.swift # Date/time picker controls
  WallpaperRenderer.swift        # Wallpaper rendering
  WallpaperService.swift         # Applies wallpaper to displays
  WallpaperTheme.swift           # Themes and event font scale
```

### Privacy

CalWall stores schedules in local `UserDefaults` and generated PNG files under `~/Library/Application Support/CalWall/`. It does not upload schedule data. The optional validation report contains only anonymous usage counts and user-selected feedback; it excludes schedule titles and schedule dates.

---

## 中文

**CalWall** 是一款注重隐私的 macOS 菜单栏应用：它把你的日程生成成日历壁纸，让计划自然出现在桌面上；同时提供轻量菜单栏面板，让你不用退出当前界面也能快速确认下一项安排。

**仓库地址：** https://github.com/lumo426/CalWall  
**下载安装：** [GitHub Releases](https://github.com/lumo426/CalWall/releases)

### 主要功能

- **菜单栏快速日程**：在任何 App 中查看下一日程和今日日程
- **日历壁纸**：支持日 / 周 / 月 / 年四种视图
- **结构化日程**：标题、日期、时间和全天日程
- 菜单栏快速添加，独立窗口管理完整日程与设置
- 浅色 / 深色 / 蓝色主题，可调整日程字号
- 中英文界面
- 开机自启、自动刷新、JSON 日程导入与导出
- 隐私优先：无需账号、不上传云端、不读取 Apple 日历
- 可主动导出本地匿名验证报告，不包含日程标题与具体日期

### 适合谁

CalWall 更适合这些 Mac 用户：

- 有多项重要日程需要记住；
- 长期使用相对稳定的工作桌面；
- 希望回到桌面时被动看到计划；
- 同时需要从菜单栏快速确认下一项安排。

它不是壁纸收藏工具，也不试图替代完整的多人协作日历。

### 快速使用

1. 从菜单栏打开 CalWall。
2. 在**快速添加**中填写标题并选择日期时间。
3. 添加日程后，CalWall 会自动生成并设置壁纸。
4. 随时打开菜单栏面板查看**下一日程**和今日日程。
5. 打开**设置**，调整壁纸视图、主题、字号、自动化和备份。

### 安装

1. 从 [Releases](https://github.com/lumo426/CalWall/releases) 下载最新的 `CalWall-vX.X.X-macOS.zip`。
2. 解压，将 `CalWall.app` 拖入**应用程序**。
3. 若 macOS 提示应用“已损坏”，执行：

```bash
xattr -cr "/Applications/CalWall.app"
```

也可以右键 App，选择**打开**。

### 本地开发

环境要求：

- macOS 14.0+
- Xcode 16+
- 当前发布包面向 Apple Silicon

用 Xcode 打开 `CalWall.xcodeproj`，配置 **Signing & Capabilities** 后按 `⌘R` 运行。

命令行编译：

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -scheme CalWall -configuration Debug \
  -derivedDataPath build/DerivedData build
```

### 项目结构

```text
CalWall/
  CalWallApp.swift               # App 入口与窗口场景
  QuickScheduleView.swift        # 菜单栏快速日程面板
  ContentView.swift              # 完整设置与日程管理
  AppState.swift                 # 状态、刷新与日程操作
  AppLocalization.swift          # 中英文文案
  AppPreferences.swift           # 自动化、备份、本地验证
  CustomScheduleItem.swift       # 日程模型与存储
  ScheduleDateTimeControls.swift # 日期时间选择器
  WallpaperRenderer.swift        # 壁纸渲染
  WallpaperService.swift         # 为显示器设置壁纸
  WallpaperTheme.swift           # 主题与日程字号
```

### 隐私

CalWall 将日程保存在本机 `UserDefaults`，生成的 PNG 位于 `~/Library/Application Support/CalWall/`。应用不会上传日程。可选的匿名验证报告只包含操作次数和用户主动选择的反馈，不包含日程标题或具体日期。

---

## License / 许可证

MIT — see / 见 [LICENSE](LICENSE)
