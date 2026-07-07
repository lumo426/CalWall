import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

enum L10n {
    enum Key {
        case appSubtitle
        case language
        case wallpaperView
        case appearance
        case blueVariant
        case customSchedule
        case customScheduleHint
        case customSchedulePlaceholder
        case saveCustomSchedule
        case noCustomEvents
        case moreItems(Int)
        case refreshWallpaper
        case updating
        case revealImage
        case quit
        case ready
        case loadingSchedule
        case generatingWallpaper
        case wallpaperUpdated(String, Int)
        case failed(String)
        case allDay
        case perspectiveDay
        case perspectiveWeek
        case perspectiveMonth
        case perspectiveYear
        case scheduleToday
        case scheduleThisWeek
        case scheduleThisMonth
        case scheduleThisYear
        case themeLight
        case themeDark
        case themeBlue
        case blueVariantLight
        case blueVariantDark
        case wallpaperDayView
        case wallpaperWeekView
        case wallpaperMonthView
        case wallpaperYearView
        case wallpaperEventCount(Int)
        case wallpaperMoreEvents(Int)
        case footerUpdated(String, String, String)
        case noDisplay
        case automation
        case launchAtLogin
        case launchAtLoginHint
        case autoRefresh
        case backup
        case exportSchedule
        case importSchedule
        case refreshManual
        case refreshEveryMinutes(Int)
        case scheduleExported
        case scheduleImported
        case backupCancelled
        case backupUnreadable
        case scheduleTitlePlaceholder
        case scheduleDateTime
        case scheduleYear
        case scheduleMonth
        case scheduleDay
        case scheduleHour
        case scheduleMinute
        case addSchedule
        case savedSchedules
        case deleteSchedule
        case eventFontSize
        case eventFontSmall
        case eventFontStandard
        case eventFontLarge
        case eventFontExtraLarge
    }

    static func text(_ key: Key, language: AppLanguage) -> String {
        switch key {
        case .appSubtitle:
            return pick(language, en: "Minimal calendar wallpaper", zh: "极简日历壁纸")
        case .language:
            return pick(language, en: "Language", zh: "语言")
        case .wallpaperView:
            return pick(language, en: "Wallpaper View", zh: "壁纸视图")
        case .appearance:
            return pick(language, en: "Appearance", zh: "外观主题")
        case .blueVariant:
            return pick(language, en: "Blue Variant", zh: "蓝色变体")
        case .customSchedule:
            return pick(language, en: "Custom Schedule", zh: "自定义日程")
        case .customScheduleHint:
            return pick(language, en: "Add events with title and date/time below. Syncs across all wallpaper views.", zh: "在下方填写标题并选择日期时间，会同步显示在日 / 周 / 月 / 年壁纸上")
        case .customSchedulePlaceholder:
            return pick(language, en: "Event title, e.g. Portfolio review", zh: "输入日程内容，例如：作品集修改")
        case .saveCustomSchedule:
            return pick(language, en: "Save Custom Schedule", zh: "保存自定义日程")
        case .noCustomEvents:
            return pick(language, en: "No custom events in this view.", zh: "当前视图没有自定义日程。")
        case .moreItems(let count):
            return pick(language, en: "+ \(count) more item(s)", zh: "+ 还有 \(count) 条")
        case .refreshWallpaper:
            return pick(language, en: "Refresh Wallpaper", zh: "刷新壁纸")
        case .updating:
            return pick(language, en: "Updating…", zh: "更新中…")
        case .revealImage:
            return pick(language, en: "Reveal Image", zh: "查看图片")
        case .quit:
            return pick(language, en: "Quit", zh: "退出")
        case .ready:
            return pick(language, en: "Ready", zh: "就绪")
        case .loadingSchedule:
            return pick(language, en: "Loading custom schedule…", zh: "加载自定义日程…")
        case .generatingWallpaper:
            return pick(language, en: "Generating calendar wallpaper…", zh: "生成日历壁纸…")
        case .wallpaperUpdated(let perspective, let count):
            return pick(language,
                        en: "\(perspective) wallpaper updated · \(count) item(s)",
                        zh: "\(perspective)壁纸已更新 · \(count) 条")
        case .failed(let error):
            return pick(language, en: "Failed: \(error)", zh: "失败：\(error)")
        case .allDay:
            return pick(language, en: "All day", zh: "全天")
        case .perspectiveDay:
            return pick(language, en: "Day", zh: "日")
        case .perspectiveWeek:
            return pick(language, en: "Week", zh: "周")
        case .perspectiveMonth:
            return pick(language, en: "Month", zh: "月")
        case .perspectiveYear:
            return pick(language, en: "Year", zh: "年")
        case .scheduleToday:
            return pick(language, en: "Today", zh: "今天")
        case .scheduleThisWeek:
            return pick(language, en: "This Week", zh: "本周")
        case .scheduleThisMonth:
            return pick(language, en: "This Month", zh: "本月")
        case .scheduleThisYear:
            return pick(language, en: "This Year", zh: "今年")
        case .themeLight:
            return pick(language, en: "Light", zh: "浅色")
        case .themeDark:
            return pick(language, en: "Dark", zh: "深色")
        case .themeBlue:
            return pick(language, en: "Blue", zh: "蓝色")
        case .blueVariantLight:
            return pick(language, en: "Blue Day", zh: "蓝色白天")
        case .blueVariantDark:
            return pick(language, en: "Blue Night", zh: "蓝色黑夜")
        case .wallpaperDayView:
            return pick(language, en: "Day view", zh: "日视图")
        case .wallpaperWeekView:
            return pick(language, en: "Week view", zh: "周视图")
        case .wallpaperMonthView:
            return pick(language, en: "Month view", zh: "月视图")
        case .wallpaperYearView:
            return pick(language, en: "Year view", zh: "年视图")
        case .wallpaperEventCount(let count):
            if language == .english {
                return count == 1 ? "1 event" : "\(count) events"
            }
            return "\(count) 个日程"
        case .wallpaperMoreEvents(let count):
            return pick(language, en: "\(count) more…", zh: "还有 \(count) 条…")
        case .footerUpdated(let perspective, let time, let screen):
            return pick(language,
                        en: "CalWall · \(perspective) · updated \(time) · \(screen)",
                        zh: "CalWall · \(perspective) · 更新于 \(time) · \(screen)")
        case .noDisplay:
            return pick(language, en: "No display was detected.", zh: "未检测到显示器。")
        case .automation:
            return pick(language, en: "Automation", zh: "省心设置")
        case .launchAtLogin:
            return pick(language, en: "Launch at Login", zh: "开机自启")
        case .launchAtLoginHint:
            return pick(language, en: "Start CalWall automatically when you log in.", zh: "登录 Mac 后自动启动 CalWall。")
        case .autoRefresh:
            return pick(language, en: "Auto Refresh", zh: "自动刷新")
        case .backup:
            return pick(language, en: "Backup", zh: "日程备份")
        case .exportSchedule:
            return pick(language, en: "Export Schedule", zh: "导出日程")
        case .importSchedule:
            return pick(language, en: "Import Schedule", zh: "导入日程")
        case .refreshManual:
            return pick(language, en: "Manual only", zh: "仅手动刷新")
        case .refreshEveryMinutes(let minutes):
            return pick(language, en: "Every \(minutes) min", zh: "每 \(minutes) 分钟")
        case .scheduleExported:
            return pick(language, en: "Schedule exported.", zh: "日程已导出。")
        case .scheduleImported:
            return pick(language, en: "Schedule imported.", zh: "日程已导入。")
        case .backupCancelled:
            return pick(language, en: "Backup cancelled.", zh: "已取消备份操作。")
        case .backupUnreadable:
            return pick(language, en: "Could not read the selected file.", zh: "无法读取所选文件。")
        case .scheduleTitlePlaceholder:
            return pick(language, en: "Event title", zh: "日程内容")
        case .scheduleDateTime:
            return pick(language, en: "Date & Time", zh: "日期与时间")
        case .scheduleYear:
            return pick(language, en: "Year", zh: "年")
        case .scheduleMonth:
            return pick(language, en: "Month", zh: "月")
        case .scheduleDay:
            return pick(language, en: "Day", zh: "日")
        case .scheduleHour:
            return pick(language, en: "Hour", zh: "时")
        case .scheduleMinute:
            return pick(language, en: "Min", zh: "分")
        case .addSchedule:
            return pick(language, en: "Add Schedule", zh: "添加日程")
        case .savedSchedules:
            return pick(language, en: "Saved Schedules", zh: "已添加日程")
        case .deleteSchedule:
            return pick(language, en: "Delete", zh: "删除")
        case .eventFontSize:
            return pick(language, en: "Event Font Size", zh: "日程字号")
        case .eventFontSmall:
            return pick(language, en: "Small", zh: "小")
        case .eventFontStandard:
            return pick(language, en: "Standard", zh: "标准")
        case .eventFontLarge:
            return pick(language, en: "Large", zh: "大")
        case .eventFontExtraLarge:
            return pick(language, en: "XL", zh: "特大")
        }
    }

    static func defaultLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .chinese : .english
    }

    private static func pick(_ language: AppLanguage, en: String, zh: String) -> String {
        language == .english ? en : zh
    }
}

extension CalendarPerspective {
    func title(language: AppLanguage) -> String {
        switch self {
        case .day: return L10n.text(.perspectiveDay, language: language)
        case .week: return L10n.text(.perspectiveWeek, language: language)
        case .month: return L10n.text(.perspectiveMonth, language: language)
        case .year: return L10n.text(.perspectiveYear, language: language)
        }
    }

    func scheduleTitle(language: AppLanguage) -> String {
        switch self {
        case .day: return L10n.text(.scheduleToday, language: language)
        case .week: return L10n.text(.scheduleThisWeek, language: language)
        case .month: return L10n.text(.scheduleThisMonth, language: language)
        case .year: return L10n.text(.scheduleThisYear, language: language)
        }
    }

    func wallpaperViewLabel(language: AppLanguage) -> String {
        switch self {
        case .day: return L10n.text(.wallpaperDayView, language: language)
        case .week: return L10n.text(.wallpaperWeekView, language: language)
        case .month: return L10n.text(.wallpaperMonthView, language: language)
        case .year: return L10n.text(.wallpaperYearView, language: language)
        }
    }
}

extension WallpaperThemeFamily {
    func title(language: AppLanguage) -> String {
        switch self {
        case .light: return L10n.text(.themeLight, language: language)
        case .dark: return L10n.text(.themeDark, language: language)
        case .blue: return L10n.text(.themeBlue, language: language)
        }
    }
}

extension BlueThemeVariant {
    func title(language: AppLanguage) -> String {
        switch self {
        case .light: return L10n.text(.blueVariantLight, language: language)
        case .dark: return L10n.text(.blueVariantDark, language: language)
        }
    }
}

final class AppLanguageStore {
    private let key = "CalWall.AppLanguage"

    var language: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let value = AppLanguage(rawValue: raw) else { return L10n.defaultLanguage() }
            return value
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}
