import AppKit
import Foundation
import ServiceManagement
import UniformTypeIdentifiers

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
