import Foundation
import AppKit

public enum CalendarPerspective: String, CaseIterable, Identifiable {
    case day
    case week
    case month
    case year

    public var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    var scheduleTitle: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }

    static let customSchedulePlaceholder = """
        输入自定义日程，每行一条，会同步显示在日/周/月/年壁纸上。例如：
        09:00 IELTS Listening
        Mon 10:00 组会
        7/10 Portfolio review
        7/19 15:00 D-DAY!
        Mar IELTS exam
        """

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
    @Published var statusMessage = "Ready"
    @Published var isWorking = false
    @Published var lastWallpaperURL: URL?
    @Published var customText: String = ""
    @Published var selectedPerspective: CalendarPerspective = .day {
        didSet {
            guard oldValue != selectedPerspective else { return }
            Task { await refresh() }
        }
    }
    @Published var themeFamily: WallpaperThemeFamily {
        didSet {
            guard oldValue != themeFamily else { return }
            themeStore.themeFamily = themeFamily
            Task { await refresh() }
        }
    }
    @Published var blueVariant: BlueThemeVariant {
        didSet {
            guard oldValue != blueVariant else { return }
            themeStore.blueVariant = blueVariant
            guard themeFamily == .blue else { return }
            Task { await refresh() }
        }
    }

    private let wallpaperService = WallpaperService()
    private let customStore = CustomScheduleStore()
    private let themeStore = WallpaperThemeStore()
    private var timer: Timer?
    private var didBootstrap = false

    init() {
        themeFamily = themeStore.themeFamily
        blueVariant = themeStore.blueVariant
    }

    func bootstrap() async {
        guard !didBootstrap else { return }
        didBootstrap = true
        customText = customStore.text()
        await refresh()
        startAutoRefresh()
    }

    func saveCustomTextAndRefresh() async {
        customStore.setText(customText)
        await refresh()
    }

    func refresh() async {
        isWorking = true
        defer { isWorking = false }

        do {
            statusMessage = "Loading custom schedule…"
            let customEvents = customStore.events(for: selectedPerspective, date: Date())
            events = customEvents.sorted { $0.startDate < $1.startDate }

            statusMessage = "Generating calendar wallpaper…"
            lastWallpaperURL = try wallpaperService.updateWallpaper(
                events: events,
                perspective: selectedPerspective,
                customText: customText,
                themeFamily: themeFamily,
                blueVariant: blueVariant
            )

            statusMessage = "\(selectedPerspective.title) wallpaper updated · \(events.count) item(s)"
        } catch {
            statusMessage = "Failed: \(error.localizedDescription)"
        }
    }

    func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}

final class CustomScheduleStore {
    private let defaults = UserDefaults.standard
    private let legacyPrefix = "CalWall.CustomSchedule."
    private let globalKey = "CalWall.CustomSchedule.global"

    func text() -> String {
        if let saved = defaults.string(forKey: globalKey) {
            return saved
        }

        var lines: [String] = []
        var seen = Set<String>()
        for perspective in CalendarPerspective.allCases {
            guard let stored = defaults.string(forKey: legacyPrefix + perspective.rawValue) else { continue }
            for line in stored.split(whereSeparator: \.isNewline) {
                let trimmed = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
                seen.insert(trimmed)
                lines.append(trimmed)
            }
        }

        let merged = lines.joined(separator: "\n")
        if !merged.isEmpty {
            defaults.set(merged, forKey: globalKey)
        }
        return merged
    }

    func setText(_ text: String) {
        defaults.set(text, forKey: globalKey)
    }

    func events(for perspective: CalendarPerspective, date: Date) -> [CalendarEvent] {
        let interval = perspective.dateInterval(containing: date)
        return allEvents(referenceDate: date).filter { event in
            event.startDate >= interval.start && event.startDate < interval.end
        }
    }

    private func allEvents(referenceDate: Date) -> [CalendarEvent] {
        let lines = text()
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return [] }
        let calendar = Calendar.current

        return lines.enumerated().compactMap { index, line in
            let parsed = parseLine(line, referenceDate: referenceDate, index: index, calendar: calendar)
            return CalendarEvent(
                id: "custom-\(index)-\(line.hashValue)",
                title: parsed.title,
                startDate: parsed.start,
                endDate: calendar.date(byAdding: .minute, value: 30, to: parsed.start) ?? parsed.start,
                isAllDay: parsed.isAllDay,
                calendarTitle: "Custom"
            )
        }
    }

    private struct ParsedLine {
        let start: Date
        let isAllDay: Bool
        let title: String
    }

    private func parseLine(_ line: String, referenceDate: Date, index: Int, calendar: Calendar) -> ParsedLine {
        if let parsed = parseMonthDayLine(line, referenceDate: referenceDate, calendar: calendar) { return parsed }
        if let parsed = parseWeekdayLine(line, referenceDate: referenceDate, calendar: calendar) { return parsed }
        if let parsed = parseMonthNameLine(line, referenceDate: referenceDate, calendar: calendar) { return parsed }
        if let parsed = parseTimeOnlyLine(line, referenceDate: referenceDate, calendar: calendar) { return parsed }

        let start = calendar.date(byAdding: .hour, value: index, to: calendar.startOfDay(for: referenceDate)) ?? referenceDate
        return ParsedLine(start: start, isAllDay: true, title: line)
    }

    private func titleAfterMatch(in line: String, match: NSTextCheckingResult) -> String {
        guard match.range.location != NSNotFound else { return line }
        let end = match.range.location + match.range.length
        guard end < (line as NSString).length else { return line }
        let remainder = (line as NSString).substring(from: end).trimmingCharacters(in: .whitespaces)
        return remainder.isEmpty ? line : remainder
    }

    private func hasCapturedRange(_ match: NSTextCheckingResult, at index: Int) -> Bool {
        let range = match.range(at: index)
        return range.location != NSNotFound && range.length > 0
    }

    private func parseMonthDayLine(_ line: String, referenceDate: Date, calendar: Calendar) -> ParsedLine? {
        let regex = try? NSRegularExpression(pattern: #"(\d{1,2})/(\d{1,2})(?:\s+(\d{1,2}):(\d{2}))?"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex?.firstMatch(in: line, range: range), match.numberOfRanges >= 3,
              let mRange = Range(match.range(at: 1), in: line), let dRange = Range(match.range(at: 2), in: line),
              let month = Int(line[mRange]), let day = Int(line[dRange]) else { return nil }

        var comps = calendar.dateComponents([.year], from: referenceDate)
        comps.month = month
        comps.day = day
        let title = titleAfterMatch(in: line, match: match)

        if hasCapturedRange(match, at: 3), hasCapturedRange(match, at: 4),
           let hRange = Range(match.range(at: 3), in: line), let minRange = Range(match.range(at: 4), in: line),
           let hour = Int(line[hRange]), let minute = Int(line[minRange]),
           (0...23).contains(hour), (0...59).contains(minute) {
            comps.hour = hour
            comps.minute = minute
            guard let start = calendar.date(from: comps) else { return nil }
            return ParsedLine(start: start, isAllDay: false, title: title)
        }

        guard let start = calendar.date(from: comps) else { return nil }
        return ParsedLine(start: calendar.startOfDay(for: start), isAllDay: true, title: title)
    }

    private func parseWeekdayLine(_ line: String, referenceDate: Date, calendar: Calendar) -> ParsedLine? {
        let lower = line.lowercased()
        let dayMap: [(String, Int)] = [
            ("monday", 0), ("mon", 0), ("周一", 0), ("星期一", 0),
            ("tuesday", 1), ("tue", 1), ("周二", 1), ("星期二", 1),
            ("wednesday", 2), ("wed", 2), ("周三", 2), ("星期三", 2),
            ("thursday", 3), ("thu", 3), ("周四", 3), ("星期四", 3),
            ("friday", 4), ("fri", 4), ("周五", 4), ("星期五", 4),
            ("saturday", 5), ("sat", 5), ("周六", 5), ("星期六", 5),
            ("sunday", 6), ("sun", 6), ("周日", 6), ("星期日", 6), ("周天", 6)
        ]

        guard let offset = dayMap.first(where: { lower.contains($0.0) })?.1 else { return nil }
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: referenceDate)?.start ?? calendar.startOfDay(for: referenceDate)
        guard var start = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }

        let timeRegex = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        if let match = timeRegex?.firstMatch(in: line, range: range), match.numberOfRanges == 3,
           let hRange = Range(match.range(at: 1), in: line), let mRange = Range(match.range(at: 2), in: line),
           let hour = Int(line[hRange]), let minute = Int(line[mRange]),
           (0...23).contains(hour), (0...59).contains(minute) {
            var comps = calendar.dateComponents([.year, .month, .day], from: start)
            comps.hour = hour
            comps.minute = minute
            start = calendar.date(from: comps) ?? start
            return ParsedLine(start: start, isAllDay: false, title: titleAfterMatch(in: line, match: match))
        }

        return ParsedLine(start: calendar.startOfDay(for: start), isAllDay: true, title: line)
    }

    private func parseMonthNameLine(_ line: String, referenceDate: Date, calendar: Calendar) -> ParsedLine? {
        let lower = line.lowercased()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for (index, symbol) in formatter.monthSymbols.enumerated() {
            guard lower.contains(symbol.lowercased()) else { continue }
            var comps = calendar.dateComponents([.year], from: referenceDate)
            comps.month = index + 1
            comps.day = 1
            guard let start = calendar.date(from: comps) else { return nil }
            return ParsedLine(start: calendar.startOfDay(for: start), isAllDay: true, title: line)
        }

        for (index, symbol) in formatter.shortMonthSymbols.enumerated() {
            guard lower.contains(symbol.lowercased()) else { continue }
            var comps = calendar.dateComponents([.year], from: referenceDate)
            comps.month = index + 1
            comps.day = 1
            guard let start = calendar.date(from: comps) else { return nil }
            return ParsedLine(start: calendar.startOfDay(for: start), isAllDay: true, title: line)
        }

        return nil
    }

    private func parseTimeOnlyLine(_ line: String, referenceDate: Date, calendar: Calendar) -> ParsedLine? {
        let regex = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex?.firstMatch(in: line, range: range), match.numberOfRanges == 3,
              let hRange = Range(match.range(at: 1), in: line), let mRange = Range(match.range(at: 2), in: line),
              let hour = Int(line[hRange]), let minute = Int(line[mRange]),
              (0...23).contains(hour), (0...59).contains(minute) else { return nil }

        var comps = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        comps.hour = hour
        comps.minute = minute
        guard let start = calendar.date(from: comps) else { return nil }
        return ParsedLine(start: start, isAllDay: false, title: titleAfterMatch(in: line, match: match))
    }
}
