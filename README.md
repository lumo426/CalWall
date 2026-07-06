# CalWall

macOS 菜单栏小工具：用**自定义日程**生成日历壁纸，自动设为桌面背景。

支持日 / 周 / 月 / 年四种壁纸视图，以及浅色、深色、蓝色（含白天/黑夜）三种外观。

## 功能

- 菜单栏常驻，点击图标打开控制面板
- 自定义日程（一行一条），同步显示在日 / 周 / 月 / 年壁纸上
- 三种外观：浅色 / 深色 / 蓝色（蓝色模式下可切换白天 / 黑夜）
- 日视图时间轴：05:00 – 23:00
- 每 30 分钟自动刷新壁纸
- 纯本地运行，不读取 Apple 日历，不上传任何数据

## 自定义日程格式

每行一条，支持以下写法：

```text
09:00 IELTS Listening          # 今天 09:00
Mon 10:00 组会                  # 本周周一 10:00
7/6 11:00 项目截止              # 7 月 6 日 11:00（时间后可不接空格）
7/10 Portfolio review           # 7 月 10 日（全天）
Mar IELTS exam                  # 3 月（年视图 / 月视图）
```

保存后切换 Day / Week / Month / Year 即可在对应壁纸上看到条目。

## 本地运行

### 环境要求

- macOS 14.0+
- Xcode 16+（或带 Swift 5 的较新版本）

### 步骤

1. 克隆仓库后，用 Xcode 打开 `CalWall.xcodeproj`
2. 选中 **CalWall** target → **Signing & Capabilities**
3. 选择你的 **Team**（个人 Apple ID 即可）
4. 如有冲突，修改 **Bundle Identifier**（例如 `com.yourname.CalWall`）
5. 点击 **Run**（⌘R）
6. 菜单栏出现日历图标，点击打开面板
7. 输入自定义日程 → **Save Custom Schedule** → 壁纸会自动更新

### 日常使用

- 应用以菜单栏形式运行（无 Dock 图标）
- 修改日程后点 **Save Custom Schedule**
- 也可手动点 **Refresh Wallpaper**
- **Reveal Image** 可查看生成的 PNG（保存在 `~/Library/Application Support/CalWall/`）
- 退出：面板右下角 **Quit**

## 开源上传到 GitHub

在项目根目录执行：

```bash
# 1. 初始化并提交
git init
git add .
git commit -m "Initial commit: CalWall custom schedule wallpaper"

# 2. 登录 GitHub（若 gh 未登录或 token 过期）
gh auth login

# 3. 创建公开仓库并推送（仓库名可自定）
gh repo create CalWall --public --source=. --remote=origin --push
```

若不用 `gh`，也可在 [github.com/new](https://github.com/new) 手动建仓库，然后：

```bash
git remote add origin https://github.com/你的用户名/CalWall.git
git branch -M main
git push -u origin main
```

## 项目结构

```text
CalWall/
  CalWallApp.swift       # 入口，菜单栏
  ContentView.swift      # 控制面板 UI
  AppState.swift         # 状态与自定义日程解析
  WallpaperRenderer.swift # 壁纸绘制
  WallpaperService.swift  # 设置桌面壁纸
  WallpaperTheme.swift    # 主题色板
  CalendarEvent.swift     # 日程模型
```

## License

MIT（可按需自行添加 LICENSE 文件）
