import AppKit
import Foundation
import ServiceManagement
import UniformTypeIdentifiers

enum ValidationAudience: String, CaseIterable, Identifiable, Codable {
    case stableDesktop = "stable-desktop"
    case wallpaperChanger = "wallpaper-changer"
    case unsure

    var id: String { rawValue }
}

enum ValidationBlocker: String, CaseIterable, Identifiable, Codable {
    case noNeed = "no-need"
    case repetitiveWallpaper = "repetitive-wallpaper"
    case manualEntry = "manual-entry"
    case installation = "installation"
    case unclearValue = "unclear-value"
    case other

    var id: String { rawValue }
}

enum ValidationHelpfulness: String, CaseIterable, Identifiable, Codable {
    case helped
    case notYet = "not-yet"
    case didNotHelp = "did-not-help"

    var id: String { rawValue }
}

enum ValidationEventName: String, CaseIterable, Codable {
    case firstLaunch
    case scheduleCreated
    case scheduleDeleted
    case wallpaperSetSuccess
    case wallpaperSetFailure
    case manualRefresh
    case feedbackSubmitted
}

struct ValidationEvent: Codable {
    let name: ValidationEventName
    let timestamp: Date
}

struct ValidationFeedback: Codable {
    let audience: ValidationAudience
    let helpfulness: ValidationHelpfulness
    let blocker: ValidationBlocker?
    let note: String
    let timestamp: Date
}

struct ValidationSnapshot {
    let firstLaunchAt: Date?
    let firstActivationAt: Date?
    let lastActivityAt: Date?
    let activeDays: Int
    let eventCounts: [ValidationEventName: Int]
    let feedback: ValidationFeedback?

    var isActivated: Bool { firstActivationAt != nil }

    func isD7Eligible(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let firstActivationAt else { return false }
        return calendar.dateComponents([.day], from: firstActivationAt, to: now).day ?? 0 >= 7
    }

    func d7Active(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let firstActivationAt else { return false }
        let daySeven = calendar.date(byAdding: .day, value: 7, to: firstActivationAt) ?? firstActivationAt
        guard now >= daySeven else { return false }
        return lastActivityAt.map { $0 >= daySeven } ?? false
    }
}

enum ValidationStore {
    private static let eventsKey = "CalWall.Validation.events.v1"
    private static let feedbackKey = "CalWall.Validation.feedback.v1"

    static func ensureFirstLaunch() {
        guard !loadEvents().contains(where: { $0.name == .firstLaunch }) else { return }
        record(.firstLaunch)
    }

    static func record(_ name: ValidationEventName) {
        var events = loadEvents()
        events.append(ValidationEvent(name: name, timestamp: Date()))
        let cutoff = Calendar.current.date(byAdding: .day, value: -180, to: Date()) ?? Date.distantPast
        events = events.filter { $0.timestamp >= cutoff }
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: eventsKey)
        }
    }

    static func saveFeedback(_ feedback: ValidationFeedback) {
        guard let data = try? JSONEncoder().encode(feedback) else { return }
        UserDefaults.standard.set(data, forKey: feedbackKey)
        record(.feedbackSubmitted)
    }

    static func snapshot(now: Date = Date()) -> ValidationSnapshot {
        let events = loadEvents()
        let activation = events.first(where: { $0.name == .wallpaperSetSuccess })?.timestamp
        let meaningfulEvents: Set<ValidationEventName> = [
            .scheduleCreated, .scheduleDeleted, .manualRefresh, .feedbackSubmitted
        ]
        let activeDates = Set(events.filter { meaningfulEvents.contains($0.name) }.map {
            Calendar.current.startOfDay(for: $0.timestamp)
        })
        let counts = Dictionary(grouping: events, by: \.name).mapValues(\.count)
        return ValidationSnapshot(
            firstLaunchAt: events.first(where: { $0.name == .firstLaunch })?.timestamp,
            firstActivationAt: activation,
            lastActivityAt: events.filter { meaningfulEvents.contains($0.name) }.map(\.timestamp).max(),
            activeDays: activeDates.count,
            eventCounts: counts,
            feedback: loadFeedback()
        )
    }

    static func exportReport(language: AppLanguage) throws -> URL? {
        let panel = NSSavePanel()
        panel.title = L10n.text(.exportValidationReport, language: language)
        panel.nameFieldStringValue = "CalWall-validation-\(fileDateStamp()).txt"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { throw ScheduleBackupError.cancelled }
        try report(language: language).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func report(language: AppLanguage) -> String {
        let snapshot = snapshot()
        let formatter = ISO8601DateFormatter()
        func date(_ value: Date?) -> String { value.map(formatter.string) ?? "-" }
        let counts = ValidationEventName.allCases.map { name in
            "\(name.rawValue): \(snapshot.eventCounts[name, default: 0])"
        }.joined(separator: "\n")
        let feedback = snapshot.feedback.map {
            "audience: \($0.audience.rawValue)\nhelpfulness: \($0.helpfulness.rawValue)\nblocker: \($0.blocker?.rawValue ?? "-")\nnote: \($0.note)"
        } ?? "-"
        return """
        CalWall anonymous validation report
        Generated: \(date(Date()))
        First launch: \(date(snapshot.firstLaunchAt))
        First activation: \(date(snapshot.firstActivationAt))
        Last meaningful activity: \(date(snapshot.lastActivityAt))
        Active days: \(snapshot.activeDays)
        D7 eligible: \(snapshot.isD7Eligible() ? "yes" : "no")
        D7 active: \(snapshot.d7Active() ? "yes" : "no")

        Event counts:
        \(counts)

        Latest feedback:
        \(feedback)
        """
    }

    private static func loadEvents() -> [ValidationEvent] {
        guard let data = UserDefaults.standard.data(forKey: eventsKey),
              let events = try? JSONDecoder().decode([ValidationEvent].self, from: data) else {
            return []
        }
        return events.sorted { $0.timestamp < $1.timestamp }
    }

    private static func loadFeedback() -> ValidationFeedback? {
        guard let data = UserDefaults.standard.data(forKey: feedbackKey) else { return nil }
        return try? JSONDecoder().decode(ValidationFeedback.self, from: data)
    }

    private static func fileDateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter.string(from: Date())
    }
}

enum AutoRefreshInterval: Int, CaseIterable, Identifiable, Codable {
    case manual = 0
    case fifteen = 15
    case thirty = 30
    case sixty = 60

    var id: Int { rawValue }

    func title(language: AppLanguage) -> String {
        switch self {
        case .manual:
            return L10n.text(.refreshManual, language: language)
        case .fifteen:
            return L10n.text(.refreshEveryMinutes(15), language: language)
        case .thirty:
            return L10n.text(.refreshEveryMinutes(30), language: language)
        case .sixty:
            return L10n.text(.refreshEveryMinutes(60), language: language)
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .manual: return nil
        case .fifteen: return 15 * 60
        case .thirty: return 30 * 60
        case .sixty: return 60 * 60
        }
    }
}

enum LaunchAtLoginManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

final class AutoRefreshStore {
    private let key = "CalWall.AutoRefreshInterval"

    var interval: AutoRefreshInterval {
        get {
            let raw = UserDefaults.standard.integer(forKey: key)
            return AutoRefreshInterval(rawValue: raw) ?? .thirty
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}

enum ScheduleBackupError: LocalizedError {
    case cancelled
    case unreadableFile

    func localizedDescription(language: AppLanguage) -> String {
        switch self {
        case .cancelled:
            return L10n.text(.backupCancelled, language: language)
        case .unreadableFile:
            return L10n.text(.backupUnreadable, language: language)
        }
    }
}

enum ScheduleBackupService {
    private static let headerPrefix = "# CalWall Custom Schedule"

    static func exportText(_ text: String, language: AppLanguage) throws -> String {
        let formatter = ISO8601DateFormatter()
        let stamp = formatter.string(from: Date())
        return """
        \(headerPrefix)
        # Exported: \(stamp)
        ---
        \(text)
        """
    }

    static func parseImportedText(_ raw: String) -> String {
        let lines = raw.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        guard let separatorIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: CharacterSet.whitespaces) == "---" }) else {
            return raw.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        let body = lines.dropFirst(separatorIndex + 1).joined(separator: "\n")
        return body.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    @MainActor
    static func exportToFile(text: String, language: AppLanguage) throws -> URL? {
        let panel = NSSavePanel()
        panel.title = L10n.text(.exportSchedule, language: language)
        panel.nameFieldStringValue = "CalWall-schedule-\(fileDateStamp()).txt"
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { throw ScheduleBackupError.cancelled }

        let payload = try exportText(text, language: language)
        try payload.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @MainActor
    static func importFromFile(language: AppLanguage) throws -> String {
        let panel = NSOpenPanel()
        panel.title = L10n.text(.importSchedule, language: language)
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { throw ScheduleBackupError.cancelled }

        guard let raw = try? String(contentsOf: url, encoding: .utf8) else {
            throw ScheduleBackupError.unreadableFile
        }
        return parseImportedText(raw)
    }

    private static func fileDateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter.string(from: Date())
    }

    @MainActor
    static func exportItems(_ items: [CustomScheduleItem], language: AppLanguage) throws -> URL? {
        let panel = NSSavePanel()
        panel.title = L10n.text(.exportSchedule, language: language)
        panel.nameFieldStringValue = "CalWall-schedule-\(fileDateStamp()).json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { throw ScheduleBackupError.cancelled }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(items)
        try data.write(to: url)
        return url
    }

    @MainActor
    static func importItems(language: AppLanguage) throws -> [CustomScheduleItem] {
        let panel = NSOpenPanel()
        panel.title = L10n.text(.importSchedule, language: language)
        panel.allowedContentTypes = [.json, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { throw ScheduleBackupError.cancelled }

        let data = try Data(contentsOf: url)
        if url.pathExtension.lowercased() == "json" {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([CustomScheduleItem].self, from: data)
        }

        guard let raw = String(data: data, encoding: .utf8) else {
            throw ScheduleBackupError.unreadableFile
        }
        let text = parseImportedText(raw)
        return LegacyScheduleTextImporter.items(from: text)
    }
}

enum LegacyScheduleTextImporter {
    static func items(from text: String) -> [CustomScheduleItem] {
        let calendar = Calendar.current
        let referenceDate = Date()
        return text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, line in
                let parsed = LegacyScheduleParser.parse(line, referenceDate: referenceDate, index: index, calendar: calendar)
                return CustomScheduleItem(title: parsed.title, startDate: parsed.start, isAllDay: parsed.isAllDay)
            }
            .sorted { $0.startDate < $1.startDate }
    }
}
