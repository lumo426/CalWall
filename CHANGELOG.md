# Changelog

本文件记录 CalWall 的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

## [Unreleased]

## [1.1.2] — 2026-07-07

### Fixed

- **日视图**：事件块在对应小时行内垂直居中，修复蓝色/粉色块上浮问题

## [1.1.1] — 2026-07-07

### Fixed

- **日程字号**：以年视图为基准重新设计字号体系，整体缩小；特大档不再异常放大
- **日视图**：事件块对齐时间刻度，标题与时间横向单行显示
- **周视图**：修复日程块上浮与日期重叠；同列字号统一
- **月视图**：限制每格最多 3 条日程，减少文字挤占

### Changed

- 字号档位：小 0.90× / 标准 1.0× / 大 1.06× / 特大 1.12×（默认标准）
- 窄列自动换行，宽列（日视图）保持单行

## [1.1.0] — 2026-07-06

GitHub Release: [v1.1.0](https://github.com/lumo426/CalWall/releases/tag/v1.1.0)

### Added

- **结构化日程编辑**：标题输入框 + 年/月/日/时/分选择器，不再需要在文本里手写 `11:00`
- **中英文界面**切换（English / 中文）
- **省心设置**：开机自启、自动刷新间隔、日程 JSON 导入/导出
- **已添加日程列表**：可查看、删除已保存条目
- 旧版纯文本日程自动迁移（`11:00 标题` 等格式会解析为结构化数据）

### Changed

- 自定义日程存储从纯文本改为 JSON（`CalWall.CustomSchedule.items.v2`）
- 控制面板布局与交互全面更新

### Fixed

- Release 安装包改用 Apple Development 签名；若仍提示「已损坏」，执行 `xattr -cr /path/to/CalWall.app`

## [1.0.0] — 2026-07-06

GitHub Release: [v.1.0.0](https://github.com/lumo426/CalWall/releases/tag/v.1.0.0)

### Added

- macOS 菜单栏应用，自定义日程生成日历壁纸
- 日 / 周 / 月 / 年四种壁纸视图
- 浅色 / 深色 / 蓝色（含白天/黑夜变体）三种外观
- 纯文本自定义日程（一行一条，支持时间前缀解析）
- 每 30 分钟自动刷新壁纸
- 纯本地运行，不读取 Apple 日历

[Unreleased]: https://github.com/lumo426/CalWall/compare/v1.1.2...HEAD
[1.1.2]: https://github.com/lumo426/CalWall/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/lumo426/CalWall/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/lumo426/CalWall/compare/v.1.0.0...v1.1.0
[1.0.0]: https://github.com/lumo426/CalWall/releases/tag/v.1.0.0
