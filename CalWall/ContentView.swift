import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    private var lang: AppLanguage { appState.language }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("CalWall")
                        .font(.title2.weight(.semibold))
                    Text(L10n.text(.appSubtitle, language: lang))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(.language, language: lang))
                    .font(.headline)
                Picker(L10n.text(.language, language: lang), selection: $appState.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appState.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(.wallpaperView, language: lang))
                    .font(.headline)
                Picker(L10n.text(.wallpaperView, language: lang), selection: $appState.selectedPerspective) {
                    ForEach(CalendarPerspective.allCases) { perspective in
                        Text(perspective.title(language: lang)).tag(perspective)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text(.appearance, language: lang))
                    .font(.headline)
                Picker(L10n.text(.appearance, language: lang), selection: $appState.themeFamily) {
                    ForEach(WallpaperThemeFamily.allCases) { theme in
                        Text(theme.title(language: lang)).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(appState.isWorking)

                if appState.themeFamily.supportsBlueVariant {
                    Picker(L10n.text(.blueVariant, language: lang), selection: $appState.blueVariant) {
                        ForEach(BlueThemeVariant.allCases) { variant in
                            Text(variant.title(language: lang)).tag(variant)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .disabled(appState.isWorking)
                }

                Text(L10n.text(.eventFontSize, language: lang))
                    .font(.subheadline.weight(.medium))
                Picker(L10n.text(.eventFontSize, language: lang), selection: $appState.eventFontScale) {
                    ForEach(WallpaperEventFontScale.allCases) { scale in
                        Text(scale.title(language: lang)).tag(scale)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(appState.isWorking)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text(.customSchedule, language: lang))
                    .font(.headline)
                Text(L10n.text(.customScheduleHint, language: lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField(L10n.text(.scheduleTitlePlaceholder, language: lang), text: $appState.draftTitle)
                    .textFieldStyle(.roundedBorder)

                Text(L10n.text(.scheduleDateTime, language: lang))
                    .font(.subheadline.weight(.medium))

                ScheduleDateTimeControls(
                    year: $appState.draftYear,
                    month: $appState.draftMonth,
                    day: $appState.draftDay,
                    hour: $appState.draftHour,
                    minute: $appState.draftMinute,
                    showsTime: !appState.draftIsAllDay,
                    language: lang
                )
                .padding(10)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Toggle(isOn: $appState.draftIsAllDay) {
                    Text(L10n.text(.allDay, language: lang))
                }

                Button {
                    Task { await appState.addScheduleItem() }
                } label: {
                    Label(L10n.text(.addSchedule, language: lang), systemImage: "plus.circle")
                }
                .disabled(
                    appState.isWorking
                        || appState.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )

                if !appState.scheduleItems.isEmpty {
                    Text(L10n.text(.savedSchedules, language: lang))
                        .font(.subheadline.weight(.medium))
                        .padding(.top, 4)

                    ForEach(appState.scheduleItems) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Text(scheduleItemDateLabel(for: item))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 118, alignment: .leading)
                            Text(item.title)
                                .font(.callout)
                                .lineLimit(2)
                            Spacer(minLength: 0)
                            Button {
                                Task { await appState.deleteScheduleItem(item) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                            .help(L10n.text(.deleteSchedule, language: lang))
                            .disabled(appState.isWorking)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appState.selectedPerspective.scheduleTitle(language: lang))
                    .font(.headline)

                if appState.events.isEmpty {
                    Text(L10n.text(.noCustomEvents, language: lang))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.events.prefix(5)) { event in
                        HStack(alignment: .top, spacing: 10) {
                            Text(timeLabel(for: event))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 68, alignment: .leading)
                            Text(event.title)
                                .font(.callout)
                                .lineLimit(1)
                        }
                    }
                    if appState.events.count > 5 {
                        Text(L10n.text(.moreItems(appState.events.count - 5), language: lang))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    Task { await appState.refresh() }
                } label: {
                    Label(
                        appState.isWorking ? L10n.text(.updating, language: lang) : L10n.text(.refreshWallpaper, language: lang),
                        systemImage: "arrow.clockwise"
                    )
                }
                .disabled(appState.isWorking)

                if let url = appState.lastWallpaperURL {
                    Button(L10n.text(.revealImage, language: lang)) {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text(.automation, language: lang))
                    .font(.headline)

                Toggle(isOn: $appState.launchAtLogin) {
                    Text(L10n.text(.launchAtLogin, language: lang))
                }
                Text(L10n.text(.launchAtLoginHint, language: lang))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(L10n.text(.autoRefresh, language: lang))
                    .font(.subheadline.weight(.medium))
                Picker(L10n.text(.autoRefresh, language: lang), selection: $appState.autoRefreshInterval) {
                    ForEach(AutoRefreshInterval.allCases) { interval in
                        Text(interval.title(language: lang)).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Text(L10n.text(.backup, language: lang))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 10) {
                    Button {
                        appState.exportSchedule()
                    } label: {
                        Label(L10n.text(.exportSchedule, language: lang), systemImage: "square.and.arrow.up")
                    }
                    Button {
                        Task { await appState.importSchedule() }
                    } label: {
                        Label(L10n.text(.importSchedule, language: lang), systemImage: "square.and.arrow.down")
                    }
                }
                .disabled(appState.isWorking)
            }

            Divider()

            HStack {
                Spacer()
                Button(L10n.text(.quit, language: lang)) { appState.quit() }
            }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 480, height: 720)
        .onChange(of: appState.language) { old, new in
            appState.handleLanguageChange(from: old, to: new)
        }
        .onChange(of: appState.selectedPerspective) { old, new in
            appState.handlePerspectiveChange(from: old, to: new)
        }
        .onChange(of: appState.themeFamily) { old, new in
            appState.handleThemeFamilyChange(from: old, to: new)
        }
        .onChange(of: appState.blueVariant) { old, new in
            appState.handleBlueVariantChange(from: old, to: new)
        }
        .onChange(of: appState.eventFontScale) { old, new in
            appState.handleEventFontScaleChange(from: old, to: new)
        }
        .onChange(of: appState.launchAtLogin) { old, new in
            appState.handleLaunchAtLoginChange(from: old, to: new)
        }
        .onChange(of: appState.autoRefreshInterval) { old, new in
            appState.handleAutoRefreshIntervalChange(from: old, to: new)
        }
    }

    private func scheduleItemDateLabel(for item: CustomScheduleItem) -> String {
        let formatter = DateFormatter()
        formatter.locale = lang.locale
        if item.isAllDay {
            formatter.dateFormat = "yyyy/M/d"
        } else {
            formatter.dateFormat = "yyyy/M/d HH:mm"
        }
        return formatter.string(from: item.startDate)
    }

    private func timeLabel(for event: CalendarEvent) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = lang.locale

        if event.isAllDay {
            switch appState.selectedPerspective {
            case .day:
                return L10n.text(.allDay, language: lang)
            default:
                formatter.dateFormat = appState.selectedPerspective == .year ? "M/d" : "M/d"
                return formatter.string(from: event.startDate)
            }
        }

        switch appState.selectedPerspective {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week, .month:
            formatter.dateFormat = "M/d HH:mm"
        case .year:
            formatter.dateFormat = calendar.component(.year, from: event.startDate) == calendar.component(.year, from: Date()) ? "M/d" : "yyyy/M/d"
        }
        return formatter.string(from: event.startDate)
    }
}
