import Foundation

struct CustomScheduleEntry: Identifiable, Codable, Hashable {
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

struct CustomScheduleDraft {
    var title: String = ""
    var year: Int
    var month: Int
    var day: Int
    var hour: Int = 9
    var minute: Int = 0
    var isAllDay: Bool = false

    init(referenceDate: Date = Date(), calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: referenceDate)
        year = components.year ?? calendar.component(.year, from: referenceDate)
        month = components.month ?? calendar.component(.month, from: referenceDate)
        day = components.day ?? calendar.component(.day, from: referenceDate)
        hour = components.hour ?? 9
        minute = components.minute ?? 0
    }

    mutating func clampDay(calendar: Calendar = .current) {
        let maxDay = Self.daysInMonth(year: year, month: month, calendar: calendar)
        if day > maxDay { day = maxDay }
    }

    func makeDate(calendar: Calendar = .current) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        if isAllDay {
            components.hour = 0
            components.minute = 0
        } else {
            components.hour = hour
            components.minute = minute
        }
        return calendar.date(from: components)
    }

    static func daysInMonth(year: Int, month: Int, calendar: Calendar = .current) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }

    static func yearOptions(referenceYear: Int) -> [Int] {
        Array((referenceYear - 1)...(referenceYear + 2))
    }
}
