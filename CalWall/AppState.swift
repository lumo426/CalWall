import Foundation
import AppKit

public enum CalendarPerspective: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    public var id: String { rawValue }

    func dateInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        switch self {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
            return DateInterval(start: start, end: end)
        case .week:
            if let interval = calendar.dateInterval(of: .weekOfYear, for: date) { return interval }
        case .month:
            if let interval = calendar.dateInterval(of: .month, for: date) { return interval }
        case .year:
            if let interval = calendar.dateInterval(of: .year, for: date) { return interval }
        }
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var statusMessage = ""
    @Published var isWorking = false
    @Published var lastWallpaperURL: URL?
    @Published var scheduleItems: [CustomScheduleItem] = []
    @Published var draftTitle: String = ""
    @Published var draftIsAllDay: Bool = false
    @Published var draftYear: Int
    @Published var draftMonth: Int
    @Published var draftDay: Int
    @Published var draftHour: Int
    @Published var draftMinute: Int
    @Published var language: AppLanguage = L10n.defaultLanguage()
    @Published var selectedPerspective: CalendarPerspective = .day
    @Published var themeFamily: WallpaperThemeFamily = .light
    @Published var blueVariant: BlueThemeVariant = .light
    @Published var eventFontScale: WallpaperEventFontScale = .standard
    @Published var launchAtLogin = false
    @Published var autoRefreshInterval: AutoRefreshInterval = .thirty
    @Published var validationAudience: ValidationAudience = .unsure
    @Published var validationHelpfulness: ValidationHelpfulness = .notYet
    @Published var validationBlocker: ValidationBlocker = .repetitiveWallpaper
    @Published var validationNote = ""
    @Published private(set) var validationSnapshot = ValidationStore.snapshot()

    private let wallpaperService = WallpaperService()
    private let customStore = CustomScheduleStore()
    private let themeStore = WallpaperThemeStore()
    private let languageStore = AppLanguageStore()
    private let autoRefreshStore = AutoRefreshStore()
    private var timer: Timer?
    private var didBootstrap = false
    private var suppressSideEffects = false
    private var refreshTask: Task<Void, Never>?

    init() {
        let now = Date()
        let calendar = Calendar.current
        draftYear = calendar.component(.year, from: now)
        draftMonth = calendar.component(.month, from: now)
        draftDay = calendar.component(.day, from: now)
        draftHour = calendar.component(.hour, from: now)
        draftMinute = (calendar.component(.minute, from: now) / 5) * 5

        suppressSideEffects = true
        themeFamily = themeStore.themeFamily
        blueVariant = themeStore.blueVariant
        eventFontScale = themeStore.eventFontScale
        language = languageStore.language
        autoRefreshInterval = autoRefreshStore.interval
        launchAtLogin = LaunchAtLoginManager.isEnabled
        statusMessage = L10n.text(.ready, language: language)
        ValidationStore.ensureFirstLaunch()
        validationSnapshot = ValidationStore.snapshot()
        suppressSideEffects = false
    }

    func saveValidationFeedback() {
        ValidationStore.saveFeedback(ValidationFeedback(
            audience: validationAudience,
            helpfulness: validationHelpfulness,
            blocker: validationBlocker,
            note: validationNote.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date()
        ))
        validationSnapshot = ValidationStore.snapshot()
        statusMessage = L10n.text(.feedbackSaved, language: language)
    }

    func exportValidationReport() {
        do {
            _ = try ValidationStore.exportReport(language: language)
            statusMessage = L10n.text(.feedbackSaved, language: language)
        } catch let error as ScheduleBackupError {
            statusMessage = error.localizedDescription(language: language)
        } catch {
            statusMessage = L10n.text(.failed(error.localizedDescription), language: language)
        }
    }

    func handleLanguageChange(from old: AppLanguage, to new: AppLanguage) {
        guard !suppressSideEffects, old != new else { return }
        scheduleSideEffect {
            self.languageStore.language = new
            await self.refresh()
        }
    }

    func handlePerspectiveChange(from old: CalendarPerspective, to new: CalendarPerspective) {
        guard !suppressSideEffects, old != new else { return }
        scheduleSideEffect { await self.refresh() }
    }

    func handleThemeFamilyChange(from old: WallpaperThemeFamily, to new: WallpaperThemeFamily) {
        guard !suppressSideEffects, old != new else { return }
        scheduleSideEffect {
            self.themeStore.themeFamily = new
            await self.refresh()
        }
    }

    func handleBlueVariantChange(from old: BlueThemeVariant, to new: BlueThemeVariant) {
        guard !suppressSideEffects, old != new else { return }
        scheduleSideEffect {
            self.themeStore.blueVariant = new
            guard self.themeFamily == .blue else { return }
            await self.refresh()
        }
    }

    func handleEventFontScaleChange(from old: WallpaperEventFontScale, to new: WallpaperEventFontScale) {
        guard !suppressSideEffects, old != new else { return }
        scheduleSideEffect {
            self.themeStore.eventFontScale = new
            await self.refresh()
        }
    }

    func handleLaunchAtLoginChange(from old: Bool, to new: Bool) {
        guard !suppressSideEffects, old != new else { return }
        scheduleSideEffect {
            do {
                try LaunchAtLoginManager.setEnabled(new)
            } catch {
                self.statusMessage = L10n.text(.failed(error.localizedDescription), language: self.language)
            }
            self.launchAtLogin = LaunchAtLoginManager.isEnabled
        }
    }

    func handleAutoRefreshIntervalChange(from old: AutoRefreshInterval, to new: AutoRefreshInterval) {
        guard !suppressSideEffects, old != new else { return }
        scheduleSideEffect {
            self.autoRefreshStore.interval = new
            self.startAutoRefresh()
        }
    }

    func exportSchedule() {
        scheduleSideEffect {
            do {
                _ = try ScheduleBackupService.exportItems(self.scheduleItems, language: self.language)
                self.statusMessage = L10n.text(.scheduleExported, language: self.language)
            } catch let error as ScheduleBackupError {
                self.statusMessage = error.localizedDescription(language: self.language)
            } catch {
                self.statusMessage = L10n.text(.failed(error.localizedDescription), language: self.language)
            }
        }
    }

    func importSchedule() async {
        do {
            let imported = try ScheduleBackupService.importItems(language: language)
            suppressSideEffects = true
            scheduleItems = imported.sorted { $0.startDate < $1.startDate }
            suppressSideEffects = false
            customStore.setItems(scheduleItems)
            await refresh()
            statusMessage = L10n.text(.scheduleImported, language: language)
        } catch let error as ScheduleBackupError {
            statusMessage = error.localizedDescription(language: language)
        } catch {
            statusMessage = L10n.text(.failed(error.localizedDescription), language: language)
        }
    }

    var todayScheduleItems: [CustomScheduleItem] {
        scheduleItems.filter { Calendar.current.isDateInToday($0.startDate) }
    }

    var nextScheduleItem: CustomScheduleItem? {
        let cutoff = Date().addingTimeInterval(-30 * 60)
        return todayScheduleItems.first { $0.isAllDay || $0.startDate >= cutoff }
    }

    func prepareQuickAdd() {
        let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let calendar = Calendar.current
        draftYear = calendar.component(.year, from: date)
        draftMonth = calendar.component(.month, from: date)
        draftDay = calendar.component(.day, from: date)
        draftHour = calendar.component(.hour, from: date)
        draftMinute = (calendar.component(.minute, from: date) / 5) * 5
        draftIsAllDay = false
    }

    func addScheduleItem() async {
        let title = draftTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        guard let startDate = composedDraftDate() else { return }
        let item = CustomScheduleItem(title: title, startDate: startDate, isAllDay: draftIsAllDay)
        scheduleItems.append(item)
        scheduleItems.sort { $0.startDate < $1.startDate }
        customStore.setItems(scheduleItems)
        draftTitle = ""
        ValidationStore.record(.scheduleCreated)
        validationSnapshot = ValidationStore.snapshot()
        await refresh()
    }

    func deleteScheduleItem(_ item: CustomScheduleItem) async {
        scheduleItems.removeAll { $0.id == item.id }
        customStore.setItems(scheduleItems)
        ValidationStore.record(.scheduleDeleted)
        validationSnapshot = ValidationStore.snapshot()
        await refresh()
    }

    func composedDraftDate() -> Date? {
        var comps = DateComponents()
        comps.year = draftYear
        comps.month = draftMonth
        comps.day = draftDay
        if draftIsAllDay {
            comps.hour = 0
            comps.minute = 0
        } else {
            comps.hour = draftHour
            comps.minute = draftMinute
        }
        return Calendar.current.date(from: comps)
    }

    private func scheduleSideEffect(_ work: @escaping @MainActor () async -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshTask?.cancel()
            self.refreshTask = Task { @MainActor in
                await work()
            }
        }
    }

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        suppressSideEffects = true
        scheduleItems = customStore.items()
        suppressSideEffects = false
        await refresh()
        startAutoRefresh()
    }

    func recordManualRefresh() {
        ValidationStore.record(.manualRefresh)
        validationSnapshot = ValidationStore.snapshot()
    }

    func refresh() async {
        isWorking = true
        defer { isWorking = false }

        do {
            statusMessage = L10n.text(.loadingSchedule, language: language)
            let customEvents = customStore.events(for: selectedPerspective, date: Date())
            events = customEvents.sorted { $0.startDate < $1.startDate }

            statusMessage = L10n.text(.generatingWallpaper, language: language)
            lastWallpaperURL = try wallpaperService.updateWallpaper(
                events: events,
                perspective: selectedPerspective,
                themeFamily: themeFamily,
                blueVariant: blueVariant,
                eventFontScale: eventFontScale,
                language: language
            )

            if !scheduleItems.isEmpty {
                ValidationStore.record(.wallpaperSetSuccess)
                validationSnapshot = ValidationStore.snapshot()
            }
            statusMessage = L10n.text(
                .wallpaperUpdated(selectedPerspective.title(language: language), events.count),
                language: language
            )
        } catch {
            ValidationStore.record(.wallpaperSetFailure)
            validationSnapshot = ValidationStore.snapshot()
            let message = (error as? WallpaperError)?.localizedDescription(language: language)
                ?? error.localizedDescription
            statusMessage = L10n.text(.failed(message), language: language)
        }
    }

    func startAutoRefresh() {
        timer?.invalidate()
        timer = nil
        guard let interval = autoRefreshInterval.timeInterval else { return }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}
