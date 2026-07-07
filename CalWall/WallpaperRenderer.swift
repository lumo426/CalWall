import AppKit
import Foundation

final class WallpaperRenderer {
    private static var palette = ThemePalette.light
    private static var language = AppLanguage.english
    private static var eventFontScale: CGFloat = 1.0

    static func render(date: Date, events: [CalendarEvent], perspective: CalendarPerspective, canvasSize: CGSize, screenName: String, themeFamily: WallpaperThemeFamily, blueVariant: BlueThemeVariant, eventFontScale: WallpaperEventFontScale, language: AppLanguage) throws -> URL {
        self.language = language
        self.eventFontScale = eventFontScale.multiplier
        configureFormatters(for: language.locale)
        palette = ThemePalette.resolve(family: themeFamily, blueVariant: blueVariant)
        let pixelsWide = max(1, Int(canvasSize.width.rounded()))
        let pixelsHigh = max(1, Int(canvasSize.height.rounded()))
        let size = CGSize(width: pixelsWide, height: pixelsHigh)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelsWide,
            pixelsHigh: pixelsHigh,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { throw RendererError.exportFailed }

        guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else { throw RendererError.exportFailed }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext
        graphicsContext.cgContext.setShouldAntialias(true)

        drawBackground(size: size)
        drawHeader(date: date, perspective: perspective, size: size)
        drawCalendarGrid(date: date, events: events, perspective: perspective, size: size)
        drawFooter(screenName: screenName, perspective: perspective, size: size)

        NSGraphicsContext.restoreGraphicsState()

        guard let png = bitmap.representation(using: .png, properties: [:]) else { throw RendererError.exportFailed }

        let folder = try outputFolder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let safeScreenName = screenName.replacingOccurrences(of: " ", with: "-")
        let themeSlug = themeFamily == .blue ? "\(themeFamily.rawValue)-\(blueVariant.rawValue)" : themeFamily.rawValue
        let url = folder.appendingPathComponent("CalWall-\(themeSlug)-\(perspective.rawValue)-\(safeScreenName)-\(formatter.string(from: date)).png")
        try png.write(to: url)
        return url
    }

    private static func outputFolder() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("CalWall", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    // MARK: - Background & Header

    private static func drawBackground(size: CGSize) {
        palette.background.setFill()
        NSRect(origin: .zero, size: size).fill()
    }

    private static func drawHeader(date: Date, perspective: CalendarPerspective, size: CGSize) {
        let calendar = Calendar.current
        let headerTop = size.height * 0.88
        let headerHeight = size.height * 0.10
        let marginX = size.width * 0.04

        // Date badge (month abbr + day)
        let badgeW = size.width * 0.055
        let badgeH = headerHeight * 0.82
        let badgeRect = NSRect(x: marginX, y: headerTop + (headerHeight - badgeH) / 2, width: badgeW, height: badgeH)
        palette.border.setStroke()
        NSBezierPath(roundedRect: badgeRect, xRadius: 8, yRadius: 8).lineWidth = 1.5
        NSBezierPath(roundedRect: badgeRect, xRadius: 8, yRadius: 8).stroke()
        palette.background.setFill()
        NSBezierPath(roundedRect: badgeRect.insetBy(dx: 1, dy: 1), xRadius: 7, yRadius: 7).fill()

        let monthAbbr = monthAbbrevFormatter.string(from: date).uppercased()
        let dayNum = "\(calendar.component(.day, from: date))"
        let abbrRect = NSRect(x: badgeRect.minX, y: badgeRect.midY + 2, width: badgeRect.width, height: badgeRect.height * 0.38)
        let dayRect = NSRect(x: badgeRect.minX, y: badgeRect.minY + 4, width: badgeRect.width, height: badgeRect.height * 0.48)
        drawFittedText(monthAbbr, in: abbrRect, maxFontSize: size.height * 0.016, minFontSize: size.height * 0.010, weight: .semibold, color: palette.textSecondary, alignment: .center)
        drawFittedText(dayNum, in: dayRect, maxFontSize: size.height * 0.032, minFontSize: size.height * 0.020, weight: .bold, color: palette.textPrimary, alignment: .center)

        // Title & subtitle
        let titleX = badgeRect.maxX + size.width * 0.025
        let titleW = size.width * 0.55
        let title = perspectiveTitle(date: date, perspective: perspective)
        let subtitle = perspectiveSubtitle(date: date, perspective: perspective)
        let titleRect = NSRect(x: titleX, y: headerTop + headerHeight * 0.48, width: titleW, height: headerHeight * 0.46)
        let subtitleRect = NSRect(x: titleX, y: headerTop + headerHeight * 0.06, width: titleW, height: headerHeight * 0.38)
        drawFittedText(title, in: titleRect, maxFontSize: size.height * 0.034, minFontSize: size.height * 0.020, weight: .bold, color: palette.textPrimary, alignment: .left)
        drawFittedText(subtitle, in: subtitleRect, maxFontSize: size.height * 0.016, minFontSize: size.height * 0.011, weight: .regular, color: palette.textSecondary, alignment: .left)

        // Perspective label (top-right)
        let viewLabel = perspectiveViewLabel(perspective)
        let labelRect = NSRect(x: size.width * 0.78, y: headerTop + headerHeight * 0.30, width: size.width * 0.16, height: headerHeight * 0.40)
        drawFittedText(viewLabel, in: labelRect, maxFontSize: size.height * 0.018, minFontSize: size.height * 0.012, weight: .medium, color: palette.textMuted, alignment: .right)
    }

    private static func perspectiveTitle(date: Date, perspective: CalendarPerspective) -> String {
        let calendar = Calendar.current
        switch perspective {
        case .day:
            return dayTitleFormatter.string(from: date)
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
                return weekTitleFormatter.string(from: date)
            }
            let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            return "\(weekTitleFormatter.string(from: interval.start)) – \(weekTitleFormatter.string(from: end))"
        case .month:
            return monthTitleFormatter.string(from: date)
        case .year:
            return yearTitleFormatter.string(from: date)
        }
    }

    private static func perspectiveSubtitle(date: Date, perspective: CalendarPerspective) -> String {
        let calendar = Calendar.current
        switch perspective {
        case .day:
            return daySubtitleFormatter.string(from: date)
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return "" }
            let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            return "\(rangeFormatter.string(from: interval.start)) – \(rangeFormatter.string(from: end))"
        case .month:
            guard let interval = calendar.dateInterval(of: .month, for: date) else { return "" }
            let end = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.end
            return "\(rangeFormatter.string(from: interval.start)) – \(rangeFormatter.string(from: end))"
        case .year:
            var startComps = DateComponents()
            startComps.year = calendar.component(.year, from: date)
            startComps.month = 1
            startComps.day = 1
            var endComps = DateComponents()
            endComps.year = calendar.component(.year, from: date)
            endComps.month = 12
            endComps.day = 31
            if let start = calendar.date(from: startComps), let end = calendar.date(from: endComps) {
                return "\(rangeFormatter.string(from: start)) – \(rangeFormatter.string(from: end))"
            }
            return yearTitleFormatter.string(from: date)
        }
    }

    private static func perspectiveViewLabel(_ perspective: CalendarPerspective) -> String {
        perspective.wallpaperViewLabel(language: language)
    }

    private static func configureFormatters(for locale: Locale) {
        monthAbbrevFormatter.locale = locale
        monthTitleFormatter.locale = locale
        weekTitleFormatter.locale = locale
        yearTitleFormatter.locale = locale
        dayTitleFormatter.locale = locale
        daySubtitleFormatter.locale = locale
        rangeFormatter.locale = locale
    }

    // MARK: - Calendar Grid

    private static func drawCalendarGrid(date: Date, events: [CalendarEvent], perspective: CalendarPerspective, size: CGSize) {
        let gridRect = NSRect(x: size.width * 0.04, y: size.height * 0.06, width: size.width * 0.92, height: size.height * 0.80)
        palette.background.setFill()
        gridRect.fill()

        palette.border.setStroke()
        let border = NSBezierPath(rect: gridRect)
        border.lineWidth = 1
        border.stroke()

        switch perspective {
        case .day:
            drawDayBoard(date: date, events: events, rect: gridRect, size: size)
        case .week:
            drawWeekBoard(date: date, events: events, rect: gridRect, size: size)
        case .month:
            drawMonthBoard(date: date, events: events, rect: gridRect, size: size)
        case .year:
            drawYearBoard(date: date, events: events, rect: gridRect, size: size)
        }
    }

    // MARK: - Month Board

    private static func drawMonthBoard(date: Date, events: [CalendarEvent], rect: NSRect, size: CGSize) {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else { return }

        let weekdayHeaderH = rect.height * 0.055
        let gridTop = rect.maxY - weekdayHeaderH
        let gridH = rect.height - weekdayHeaderH
        let cellW = rect.width / 7
        let cellH = gridH / 6

        let weekdays = orderedWeekdaySymbols(calendar: calendar)
        for i in 0..<7 {
            let cell = NSRect(x: rect.minX + CGFloat(i) * cellW, y: gridTop, width: cellW, height: weekdayHeaderH)
            palette.backgroundSubtle.setFill()
            cell.fill()
            strokeCellBorder(cell)
            let labelRect = cell.insetBy(dx: 4, dy: 4)
            drawFittedText(weekdays[i], in: labelRect, maxFontSize: size.height * 0.014, minFontSize: size.height * 0.009, weight: .medium, color: palette.textSecondary, alignment: .center)
        }

        let grouped = Dictionary(grouping: events) { calendar.startOfDay(for: $0.startDate) }

        let dateNumberZoneH = cellH * 0.22
        let eventZoneTopInset = dateNumberZoneH + cellH * 0.04
        let pillH = scaledPillHeight(0.022, canvas: size)
        let pillGap = scaledPillHeight(0.005, canvas: size)
        let maxPills = max(1, Int((cellH - eventZoneTopInset - pillH * 0.6) / (pillH + pillGap)))

        for index in 0..<42 {
            guard let day = calendar.date(byAdding: .day, value: index, to: firstWeek.start) else { continue }
            let col = index % 7
            let row = index / 7
            let cell = NSRect(x: rect.minX + CGFloat(col) * cellW, y: gridTop - CGFloat(row + 1) * cellH, width: cellW, height: cellH)
            palette.background.setFill()
            cell.fill()
            strokeCellBorder(cell)

            let sameMonth = calendar.isDate(day, equalTo: date, toGranularity: .month)
            let dayNum = calendar.component(.day, from: day)
            let isToday = calendar.isDateInToday(day)
            let numColor = sameMonth ? palette.textPrimary : palette.textMuted.withAlphaComponent(0.45)

            let numRect = NSRect(x: cell.minX + 8, y: cell.maxY - dateNumberZoneH, width: cell.width - 16, height: dateNumberZoneH - 4)
            if isToday {
                let circleSize = min(dateNumberZoneH * 0.85, 28 * size.height / 1080)
                let circleRect = NSRect(x: cell.minX + 8, y: cell.maxY - dateNumberZoneH + (dateNumberZoneH - circleSize) / 2, width: circleSize, height: circleSize)
                palette.textPrimary.setFill()
                NSBezierPath(ovalIn: circleRect).fill()
                let todayRect = NSRect(x: circleRect.minX, y: circleRect.minY + 1, width: circleRect.width, height: circleRect.height)
                drawFittedText("\(dayNum)", in: todayRect, maxFontSize: size.height * 0.015, minFontSize: size.height * 0.010, weight: .semibold, color: .white, alignment: .center)
            } else {
                drawFittedText("\(dayNum)", in: numRect, maxFontSize: size.height * 0.016, minFontSize: size.height * 0.010, weight: .regular, color: numColor, alignment: .left)
            }

            let todays = grouped[calendar.startOfDay(for: day)] ?? []
            let eventRect = NSRect(x: cell.minX + 6, y: cell.minY + pillH * 0.5, width: cell.width - 12, height: cell.height - eventZoneTopInset - pillH * 0.5)
            drawEventPills(todays, in: eventRect, maxItems: maxPills, pillHeight: pillH, pillGap: pillGap, size: size)
        }
    }

    // MARK: - Week Board

    private static func drawWeekBoard(date: Date, events: [CalendarEvent], rect: NSRect, size: CGSize) {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .weekOfYear, for: date) ?? DateInterval(start: date, duration: 7 * 86400)
        let cellW = rect.width / 7
        let headerH = rect.height * 0.12
        let grouped = Dictionary(grouping: events) { calendar.startOfDay(for: $0.startDate) }

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale.current
        weekdayFormatter.dateFormat = "EEE"

        let pillH = scaledPillHeight(0.024, canvas: size)
        let pillGap = scaledPillHeight(0.006, canvas: size)

        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: interval.start) else { continue }
            let cell = NSRect(x: rect.minX + CGFloat(i) * cellW, y: rect.minY, width: cellW, height: rect.height)
            palette.background.setFill()
            cell.fill()
            strokeCellBorder(cell)

            let isToday = calendar.isDateInToday(day)
            let header = NSRect(x: cell.minX, y: cell.maxY - headerH, width: cell.width, height: headerH)
            (isToday ? palette.backgroundSubtle : palette.background).setFill()
            header.fill()
            strokeCellBorder(header)

            let weekdayRect = NSRect(x: cell.minX + 4, y: header.midY, width: cell.width - 8, height: headerH * 0.42)
            let dayNumRect = NSRect(x: cell.minX + 4, y: header.minY + 4, width: cell.width - 8, height: headerH * 0.48)

            drawFittedText(weekdayFormatter.string(from: day), in: weekdayRect, maxFontSize: size.height * 0.014, minFontSize: size.height * 0.009, weight: .medium, color: palette.textSecondary, alignment: .center)

            if isToday {
                let circleSize = min(headerH * 0.55, 32 * size.height / 1080)
                let circleRect = NSRect(x: cell.midX - circleSize / 2, y: dayNumRect.minY + (dayNumRect.height - circleSize) / 2, width: circleSize, height: circleSize)
                palette.textPrimary.setFill()
                NSBezierPath(ovalIn: circleRect).fill()
                let todayRect = NSRect(x: circleRect.minX, y: circleRect.minY + 1, width: circleRect.width, height: circleRect.height)
                drawFittedText("\(calendar.component(.day, from: day))", in: todayRect, maxFontSize: size.height * 0.018, minFontSize: size.height * 0.012, weight: .semibold, color: .white, alignment: .center)
            } else {
                drawFittedText("\(calendar.component(.day, from: day))", in: dayNumRect, maxFontSize: size.height * 0.022, minFontSize: size.height * 0.014, weight: .semibold, color: palette.textPrimary, alignment: .center)
            }

            let eventAreaH = rect.height - headerH - pillH
            let maxPills = max(1, Int((eventAreaH - pillH) / (pillH + pillGap)))
            let eventRect = NSRect(x: cell.minX + 8, y: cell.minY + pillH * 0.4, width: cell.width - 16, height: eventAreaH)
            drawEventPills(grouped[calendar.startOfDay(for: day)] ?? [], in: eventRect, maxItems: maxPills, pillHeight: pillH, pillGap: pillGap, size: size)
        }
    }

    // MARK: - Day Board

    private static func drawDayBoard(date: Date, events: [CalendarEvent], rect: NSRect, size: CGSize) {
        let calendar = Calendar.current
        let hours = Array(5...23)
        let dayHeaderH = rect.height * 0.08
        let timeColW = rect.width * 0.10
        let contentX = rect.minX + timeColW
        let contentW = rect.width - timeColW
        let gridH = rect.height - dayHeaderH
        let rowH = gridH / CGFloat(hours.count)

        // Day header bar
        let dayHeader = NSRect(x: rect.minX, y: rect.maxY - dayHeaderH, width: rect.width, height: dayHeaderH)
        palette.backgroundSubtle.setFill()
        dayHeader.fill()
        strokeCellBorder(dayHeader)

        let dayTitle = dayTitleFormatter.string(from: date)
        let daySubtitle = daySubtitleFormatter.string(from: date)
        drawFittedText(dayTitle, in: NSRect(x: rect.minX + 20, y: dayHeader.midY, width: rect.width * 0.5, height: dayHeaderH * 0.50), maxFontSize: size.height * 0.028, minFontSize: size.height * 0.018, weight: .bold, color: palette.textPrimary, alignment: .left)
        drawFittedText(daySubtitle, in: NSRect(x: rect.minX + 20, y: dayHeader.minY + 6, width: rect.width * 0.5, height: dayHeaderH * 0.40), maxFontSize: size.height * 0.014, minFontSize: size.height * 0.010, weight: .regular, color: palette.textSecondary, alignment: .left)

        let eventCount = events.count
        if eventCount > 0 {
            drawFittedText(L10n.text(.wallpaperEventCount(eventCount), language: language), in: NSRect(x: rect.maxX - rect.width * 0.22, y: dayHeader.minY + 8, width: rect.width * 0.18, height: dayHeaderH - 16), maxFontSize: size.height * 0.014, minFontSize: size.height * 0.010, weight: .medium, color: palette.textMuted, alignment: .right)
        }

        for (index, hour) in hours.enumerated() {
            let y = rect.maxY - dayHeaderH - CGFloat(index + 1) * rowH
            let row = NSRect(x: rect.minX, y: y, width: rect.width, height: rowH)
            (index % 2 == 0 ? palette.background : palette.backgroundSubtle).setFill()
            row.fill()
            strokeCellBorder(row)

            let timeRect = NSRect(x: rect.minX + 8, y: row.midY - rowH * 0.25, width: timeColW - 12, height: rowH * 0.50)
            drawFittedText(String(format: "%02d:00", hour), in: timeRect, maxFontSize: size.height * 0.013, minFontSize: size.height * 0.009, weight: .regular, color: palette.textMuted, alignment: .right)
        }

        let sorted = events.sorted { $0.startDate < $1.startDate }
        for event in sorted {
            var hour = calendar.component(.hour, from: event.startDate)
            let minute = calendar.component(.minute, from: event.startDate)
            if event.isAllDay || hour < hours.first! || hour > hours.last! {
                hour = hours.first!
            }
            let hourIndex = hour - hours.first!
            let fraction = event.isAllDay ? 0 : CGFloat(minute) / 60.0
            let y = rect.maxY - dayHeaderH - (CGFloat(hourIndex) + fraction + 1) * rowH
            let pillH = min(rowH * 0.75, scaledPillHeight(0.028, canvas: size))
            let pillRect = NSRect(x: contentX + 12, y: y, width: contentW - 24, height: pillH)
            drawSingleEventPill(event, in: pillRect, size: size, showTime: !event.isAllDay)
        }
    }

    // MARK: - Year Board

    private static func drawYearBoard(date: Date, events: [CalendarEvent], rect: NSRect, size: CGSize) {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let currentMonth = calendar.component(.month, from: date)
        let cellW = rect.width / 4
        let cellH = rect.height / 3
        let grouped = Dictionary(grouping: events) { calendar.component(.month, from: $0.startDate) }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale.current
        monthFormatter.dateFormat = "MMMM"

        let headerH = cellH * 0.18
        let pillH = scaledPillHeight(0.018, canvas: size)
        let pillGap = scaledPillHeight(0.004, canvas: size)

        for month in 1...12 {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = 1
            guard let monthDate = calendar.date(from: comps) else { continue }

            let col = (month - 1) % 4
            let row = (month - 1) / 4
            let cell = NSRect(x: rect.minX + CGFloat(col) * cellW, y: rect.maxY - CGFloat(row + 1) * cellH, width: cellW, height: cellH)
            palette.background.setFill()
            cell.fill()
            strokeCellBorder(cell)

            let header = NSRect(x: cell.minX, y: cell.maxY - headerH, width: cell.width, height: headerH)
            (month == currentMonth ? palette.todayHighlight : palette.backgroundSubtle).setFill()
            header.fill()
            strokeCellBorder(header)

            let monthName = monthFormatter.string(from: monthDate)
            let monthNum = "\(month)"
            let nameRect = NSRect(x: cell.minX + 10, y: header.minY + headerH * 0.08, width: cell.width - 50, height: headerH * 0.55)
            let numRect = NSRect(x: cell.maxX - 42, y: header.minY + headerH * 0.15, width: 32, height: headerH * 0.70)

            drawFittedText(monthName, in: nameRect, maxFontSize: size.height * 0.016, minFontSize: size.height * 0.010, weight: month == currentMonth ? .bold : .semibold, color: month == currentMonth ? .white : palette.textPrimary, alignment: .left)
            drawFittedText(monthNum, in: numRect, maxFontSize: size.height * 0.014, minFontSize: size.height * 0.009, weight: .medium, color: month == currentMonth ? NSColor.white.withAlphaComponent(0.8) : palette.textMuted, alignment: .right)

            let monthEvents = grouped[month] ?? []
            let eventAreaH = cell.height - headerH - pillH
            let maxPills = max(1, Int((eventAreaH - pillH) / (pillH + pillGap)))
            let eventRect = NSRect(x: cell.minX + 8, y: cell.minY + pillH * 0.3, width: cell.width - 16, height: eventAreaH)
            drawEventPills(monthEvents, in: eventRect, maxItems: maxPills, pillHeight: pillH, pillGap: pillGap, size: size, compact: true)
        }
    }

    // MARK: - Events

    private static func drawEventPills(_ events: [CalendarEvent], in rect: NSRect, maxItems: Int, pillHeight: CGFloat, pillGap: CGFloat, size: CGSize, compact: Bool = false) {
        guard !events.isEmpty else { return }
        let visible = Array(events.prefix(maxItems))
        var y = rect.maxY - pillHeight

        for (index, event) in visible.enumerated() {
            guard y >= rect.minY else { break }
            let pillRect = NSRect(x: rect.minX, y: y, width: rect.width, height: pillHeight)
            drawSingleEventPill(event, in: pillRect, size: size, showTime: !compact, colorIndex: index)
            y -= pillHeight + pillGap
        }

        if events.count > visible.count {
            let moreRect = NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: pillHeight * 0.85)
            drawFittedText(L10n.text(.wallpaperMoreEvents(events.count - visible.count), language: language), in: moreRect, maxFontSize: eventFontMax(0.012, canvas: size), minFontSize: eventFontMin(0.009, canvas: size), weight: .medium, color: palette.textMuted, alignment: .left)
        }
    }

    private static func drawSingleEventPill(_ event: CalendarEvent, in rect: NSRect, size: CGSize, showTime: Bool, colorIndex: Int = 0) {
        let colors = palette.eventColors[colorIndex % palette.eventColors.count]
        let pillRect = rect.insetBy(dx: 0, dy: 1)
        colors.bg.setFill()
        NSBezierPath(roundedRect: pillRect, xRadius: 6, yRadius: 6).fill()

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = event.isAllDay ? "" : "HH:mm"
        let timeStr = event.isAllDay ? "" : timeFormatter.string(from: event.startDate)

        let padding: CGFloat = 8
        var titleW = pillRect.width - padding * 2
        if showTime, !timeStr.isEmpty {
            let timeW = pillRect.width * 0.28
            let timeRect = NSRect(x: pillRect.maxX - timeW - padding / 2, y: pillRect.minY, width: timeW, height: pillRect.height)
            drawFittedText(timeStr, in: timeRect, maxFontSize: eventFontMax(0.012, canvas: size), minFontSize: eventFontMin(0.009, canvas: size), weight: .medium, color: colors.fg.withAlphaComponent(0.85), alignment: .right)
            titleW = pillRect.width - timeW - padding * 2
        }

        let title = event.title
        let titleRect = NSRect(x: pillRect.minX + padding, y: pillRect.minY, width: max(20, titleW), height: pillRect.height)
        drawFittedText(title, in: titleRect, maxFontSize: eventFontMax(0.013, canvas: size), minFontSize: eventFontMin(0.009, canvas: size), weight: .medium, color: colors.fg, alignment: .left, truncate: true)
    }

    // MARK: - Footer

    private static func drawFooter(screenName: String, perspective: CalendarPerspective, size: CGSize) {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: Date())
        let text = L10n.text(
            .footerUpdated(perspective.title(language: language), time, screenName),
            language: language
        )
        let footerRect = NSRect(x: size.width * 0.04, y: size.height * 0.018, width: size.width * 0.92, height: size.height * 0.025)
        drawFittedText(text, in: footerRect, maxFontSize: size.height * 0.011, minFontSize: size.height * 0.008, weight: .regular, color: palette.textMuted, alignment: .left)
    }

    // MARK: - Drawing Helpers

    private static func scaledPillHeight(_ base: CGFloat, canvas: CGSize) -> CGFloat {
        canvas.height * base * eventFontScale
    }

    private static func eventFontMax(_ base: CGFloat, canvas: CGSize) -> CGFloat {
        canvas.height * base * eventFontScale
    }

    private static func eventFontMin(_ base: CGFloat, canvas: CGSize) -> CGFloat {
        canvas.height * base * eventFontScale
    }

    private static func strokeCellBorder(_ rect: NSRect) {
        palette.border.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 1
        path.stroke()
    }

    private static func orderedWeekdaySymbols(calendar: Calendar) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        let symbols = formatter.shortWeekdaySymbols ?? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let start = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }

    private static func drawFittedText(
        _ text: String,
        in rect: NSRect,
        maxFontSize: CGFloat,
        minFontSize: CGFloat,
        weight: NSFont.Weight,
        color: NSColor,
        alignment: NSTextAlignment,
        truncate: Bool = false
    ) {
        guard !text.isEmpty else { return }
        let font = fitFont(text: text, in: rect, maxSize: maxFontSize, minSize: minFontSize, weight: weight)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = truncate ? .byTruncatingTail : .byClipping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        text.draw(in: rect, withAttributes: attributes)
    }

    private static func fitFont(text: String, in rect: NSRect, maxSize: CGFloat, minSize: CGFloat, weight: NSFont.Weight) -> NSFont {
        var size = maxSize
        while size >= minSize {
            let font = NSFont.systemFont(ofSize: size, weight: weight)
            let bounds = (text as NSString).boundingRect(
                with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font]
            )
            if bounds.width <= rect.width && bounds.height <= rect.height {
                return font
            }
            size -= 0.5
        }
        return NSFont.systemFont(ofSize: minSize, weight: weight)
    }

    // MARK: - Date Formatters

    private static let monthAbbrevFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMM"
        return f
    }()

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let weekTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMM d"
        return f
    }()

    private static let yearTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "yyyy"
        return f
    }()

    private static let dayTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "EEEE, MMMM d"
        return f
    }()

    private static let daySubtitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "yyyy"
        return f
    }()

    private static let rangeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMM d, yyyy"
        return f
    }()
}

enum RendererError: LocalizedError {
    case exportFailed

    var errorDescription: String? {
        switch self {
        case .exportFailed:
            return "The wallpaper image could not be exported."
        }
    }
}

