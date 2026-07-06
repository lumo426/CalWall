# CalWall

macOS 菜单栏小工具：用**自定义日程**生成日历壁纸，自动设为桌面背景。

支持日 / 周 / 月 / 年四种壁纸视图，以及浅色、深色、蓝色（含白天/黑夜）三种外观。

**仓库地址：** https://github.com/lumo426/CalWall

## 功能

- 菜单栏常驻，点击图标打开控制面板
- 自定义日程（一行一条），同步显示在日 / 周 / 月 / 年壁纸上
- 三种外观：浅色 / 深色 / 蓝色（蓝色模式下可切换白天 / 黑夜）
- 日视图时间轴：05:00 – 23:00
- 每 30 分钟自动刷新壁纸
- 纯本地运行，不读取 Apple 日历，不上传任何数据

## 自定义日程格式

每行一条，全局共用，支持以下写法：

```text
09:00 IELTS Listening          # 今天 09:00
Mon 10:00 组会                  # 本周周一 10:00
7/6 11:00 项目截止              # 7 月 6 日 11:00（时间后可不接空格）
7/10 Portfolio review           # 7 月 10 日（全天）
Mar IELTS exam                  # 3 月（年视图 / 月视图）
```

保存后切换 Day / Week / Month / Year 即可在对应壁纸上看到条目。

---

## 本地开发与运行

### 环境要求

- macOS 14.0+
- Xcode 16+（或带 Swift 5 的较新版本）

### 首次配置

1. 克隆仓库后，用 Xcode 打开 `CalWall.xcodeproj`
2. 左侧点蓝色 **CalWall** 项目 → **TARGETS → CalWall → Signing & Capabilities**
3. 勾选 **Automatically manage signing**
4. **Team** 选择你的 Apple ID（Personal Team 即可）
5. 如有冲突，修改 **Bundle Identifier**（例如 `com.lumo426.CalWall`）
6. 点击 **Run**（⌘R）

### 设置 App 图标

1. 左侧 **Assets.xcassets → AppIcon**
2. 准备 **1024×1024 PNG**（正方形，无需自己裁圆角）
3. 拖到最大格子（512pt @2x）
4. **Product → Clean Build Folder**（⇧⌘K）→ **Build**（⌘B）

### 日常使用

- 应用以菜单栏形式运行（无 Dock 图标）
- 输入自定义日程 → **Save Custom Schedule** → 壁纸自动更新
- 也可手动点 **Refresh Wallpaper**
- **Reveal Image** 可查看生成的 PNG（保存在 `~/Library/Application Support/CalWall/`）
- 退出：面板右下角 **Quit**

### 首次打开被系统拦截

未签名的 App 可能被 Gatekeeper 拦截，可任选其一：

- 右键 `CalWall.app` → **打开** → 再点 **打开**
- 或在终端执行：

```bash
xattr -cr /Applications/CalWall.app
```

---

## 上传到 GitHub

### 浏览器 vs 终端

浏览器能打开 GitHub，不代表终端能推送。终端需要：**网络通** + **Git 授权**。

### 代理配置（示例：SakuraCat 端口 7897）

若终端访问 GitHub 超时，每次推送前先执行：

```bash
export https_proxy=http://127.0.0.1:7897
export http_proxy=http://127.0.0.1:7897
```

测试连通：

```bash
curl -I https://github.com
```

看到 `HTTP/2 200` 即表示成功。也可在代理软件中开启 **TUN 模式**，终端会自动走代理。

### 创建 GitHub 仓库（网页）

1. 打开 [github.com/new](https://github.com/new)
2. 仓库名：`CalWall`，选 **Public**
3. **不要**勾选 Add README / .gitignore / license（本地已有）
4. 点 **Create repository**

### 本地 Git 推送

```bash
cd /path/to/CalWall_Dopamine_Custom

git init
git add .
git commit -m "Initial commit: CalWall custom schedule wallpaper for macOS."

git remote add origin https://github.com/lumo426/CalWall.git
git push -u origin main
```

登录时：

- **Username**：你的 GitHub 用户名
- **Password**：填 [Personal Access Token](https://github.com/settings/tokens)（不是登录密码）

若提示 `remote origin already exists`：

```bash
git remote set-url origin https://github.com/lumo426/CalWall.git
git push -u origin main
```

---

## 打包安装包（zip / dmg）

### 1. Release 编译

1. **Product → Scheme → Edit Scheme → Run → Build Configuration → Release**
2. **Product → Build**（⌘B）
3. **Product → Show Build Folder in Finder**
4. 进入 **Products → Release → CalWall.app**

### 2. 打 zip（推荐）

```bash
cd [Release 文件夹路径]
ditto -c -k --keepParent CalWall.app ~/Desktop/CalWall-v1.0.0-macOS.zip
```

或在 DerivedData 中查找：

```bash
cd ~/Library/Developer/Xcode/DerivedData
APP=$(find . -path "*/Release/CalWall.app" 2>/dev/null | head -1)
cd "$(dirname "$APP")"
ditto -c -k --keepParent CalWall.app ~/Desktop/CalWall-v1.0.0-macOS.zip
```

### 3. 打 dmg（可选）

```bash
hdiutil create -volname "CalWall" -srcfolder CalWall.app -ov -format UDZO ~/Desktop/CalWall-v1.0.0.dmg
```

### 4. 上传到 GitHub Release

1. 打开 https://github.com/lumo426/CalWall/releases/new
2. **Tag**：`v1.0.0`（Create new tag on publish）
3. **Title**：`CalWall 1.0.0`
4. 填写 Release notes
5. 把 zip 拖进 **Attach binaries**
6. 点 **Publish release**

---

## 后续迭代

```text
改代码 → 本地测试 → git push →（可选）发新 Release
```

### 日常改代码并推送

```bash
export https_proxy=http://127.0.0.1:7897
export http_proxy=http://127.0.0.1:7897

cd /path/to/CalWall_Dopamine_Custom

git status
git add .
git commit -m "描述这次改了什么"
git push
```

**Commit 消息示例：**

- `Add week view event labels`
- `Fix day view time parsing for 7/6 11:00`
- `Update blue dark theme colors`

### 发新版安装包

1. Xcode **General** 里改 **Version**（如 1.0 → 1.1）和 **Build**
2. Release 模式重新 **Build**
3. 重新打 zip
4. GitHub 新建 Release，Tag 如 `v1.1.0`，上传新 zip

### 更新已安装的 App

- **不用卸载**，直接覆盖安装即可
- Xcode **Run**，或把新 `CalWall.app` 拖进「应用程序」选 **替换**
- 自定义日程一般会保留
- 若菜单栏出现两个图标：先 **Quit** 旧进程，再开新版

---

## 常见问题

| 问题 | 处理 |
|------|------|
| `gh auth login` 超时 | 终端设代理，或用 Token + `git push` |
| `Repository not found` | 确认网页已 Create repository，或检查 remote URL |
| 日视图有「1 event」但时间轴空 | 日程格式需含时间，如 `7/6 11:00 标题` |
| 终端连不上 GitHub | 开代理，设端口或开 TUN 模式 |
| 没有 App 图标 | **Assets.xcassets → AppIcon** 拖入 1024×1024 PNG |
| 换了 Bundle Identifier | 相当于新 App，需手动删除旧版 |

---

## 项目结构

```text
CalWall/
  CalWallApp.swift        # 入口，菜单栏
  ContentView.swift       # 控制面板 UI
  AppState.swift          # 状态与自定义日程解析
  WallpaperRenderer.swift # 壁纸绘制
  WallpaperService.swift  # 设置桌面壁纸
  WallpaperTheme.swift    # 主题色板
  CalendarEvent.swift     # 日程模型
```

## License

MIT — 见 [LICENSE](LICENSE)
