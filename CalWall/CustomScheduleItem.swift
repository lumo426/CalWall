import Foundation

struct CustomScheduleItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date
    var isAllDay: Bool

    init(id: UUID = UUID(), title: String, startDate: Date, isAllDay: Bool) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.isAllDay = isAllDay
    }

    func calendarEvent(calendar: Calendar = .current) -> CalendarEvent {
        CalendarEvent(
            id: "custom-\(id.uuidString)",
            title: title,
            startDate: startDate,
            endDate: calendar.date(byAdding: .minute, value: 30, to: startDate) ?? startDate,
            isAllDay: isAllDay,
            calendarTitle: "Custom"
        )
    }
}

final class CustomScheduleStore {
    private let defaults = UserDefaults.standard
    private let itemsKey = "CalWall.CustomSchedule.items.v2"
    private let legacyTextKey = "CalWall.CustomSchedule.global"
    private let legacyPrefix = "CalWall.CustomSchedule."

    func items() -> [CustomScheduleItem] {
        if let data = defaults.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([CustomScheduleItem].self, from: data) {
            return decoded.sorted { $0.startDate < $1.startDate }
        }

        let migrated = migrateLegacyText()
        if !migrated.isEmpty {
            setItems(migrated)
        }
        return migrated
    }

    func setItems(_ items: [CustomScheduleItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: itemsKey)
    }

    func events(for perspective: CalendarPerspective, date: Date) -> [CalendarEvent] {
        let interval = perspective.dateInterval(containing: date)
        return items()
            .map { $0.calendarEvent() }
            .filter { $0.startDate >= interval.start && $0.startDate < interval.end }
    }

    private func migrateLegacyText() -> [CustomScheduleItem] {
        let raw = legacyPlainText()
        guard !raw.isEmpty else { return [] }

        let calendar = Calendar.current
        let referenceDate = Date()
        return raw
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, line in
                let parsed = LegacyScheduleParser.parse(line, referenceDate: referenceDate, index: index, calendar: calendar)
                return CustomScheduleItem(title: parsed.title, startDate: parsed.start, isAllDay: parsed.isAllDay)
            }
    }

    private func legacyPlainText() -> String {
        if let saved = defaults.string(forKey: legacyTextKey) {
            return saved
        }

        var lines: [String] = []
        var seen = Set<String>()
        for perspective in CalendarPerspective.allCases {
            guard let stored = defaults.string(forKey: legacyPrefix + perspective.rawValue) else { continue }
            for line in stored.split(whereSeparator: \.isNewline) {
                let trimmed = String(line).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
                seen.insert(trimmed)
                lines.append(trimmed)
            }
        }
        return lines.joined(separator: "\n")
    }
}

enum LegacyScheduleParser {
    struct ParsedLine {
        let start: Date
        let isAllDay: Bool
        let title: String
    }

    static func parse(_ line: String, referenceDate: Date, index: Int, calendar: Calendar) -> ParsedLine {
        if let parsed = parseMonthDayLine(line, referenceDate: referenceDate, calendar: calendar) { return parsed }
        if let parsed = parseTimeOnlyLine(line, referenceDate: referenceDate, calendar: calendar) { return parsed }

        let start = calendar.date(byAdding: .hour, value: index, to: calendar.startOfDay(for: referenceDate)) ?? referenceDate
        return ParsedLine(start: start, isAllDay: true, title: line)
    }

    private static func parseMonthDayLine(_ line: String, referenceDate: Date, calendar: Calendar) -> ParsedLine? {
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
           let hour = Int(line[hRange]), let minute = Int(line[minRange]) {
            comps.hour = hour
            comps.minute = minute
            guard let start = calendar.date(from: comps) else { return nil }
            return ParsedLine(start: start, isAllDay: false, title: title)
        }

        guard let start = calendar.date(from: comps) else { return nil }
        return ParsedLine(start: calendar.startOfDay(for: start), isAllDay: true, title: title)
    }

    private static func parseTimeOnlyLine(_ line: String, referenceDate: Date, calendar: Calendar) -> ParsedLine? {
        let regex = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#)
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex?.firstMatch(in: line, range: range), match.numberOfRanges == 3,
              let hRange = Range(match.range(at: 1), in: line), let mRange = Range(match.range(at: 2), in: line),
              let hour = Int(line[hRange]), let minute = Int(line[mRange]) else { return nil }

        var comps = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        comps.hour = hour
        comps.minute = minute
        guard let start = calendar.date(from: comps) else { return nil }
        return ParsedLine(start: start, isAllDay: false, title: titleAfterMatch(in: line, match: match))
    }

    private static func titleAfterMatch(in line: String, match: NSTextCheckingResult) -> String {
        guard match.range.location != NSNotFound else { return line }
        let end = match.range.location + match.range.length
        guard end < (line as NSString).length else { return line }
        let remainder = (line as NSString).substring(from: end).trimmingCharacters(in: CharacterSet.whitespaces)
        return remainder.isEmpty ? line : remainder
    }

    private static func hasCapturedRange(_ match: NSTextCheckingResult, at index: Int) -> Bool {
        let range = match.range(at: index)
        return range.location != NSNotFound && range.length > 0
    }
}
