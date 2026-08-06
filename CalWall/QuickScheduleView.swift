import SwiftUI

struct QuickScheduleView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openWindow) private var openWindow

    private var lang: AppLanguage { appState.language }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            nextSchedule
            todaySchedule
            quickAdd
            footer
        }
        .padding(18)
        .frame(width: 390)
        .task {
            if appState.draftTitle.isEmpty {
                appState.prepareQuickAdd()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text("CalWall")
                    .font(.headline)
                Text(formattedToday)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if appState.isWorking {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var nextSchedule: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L10n.text(.nextSchedule, language: lang), systemImage: "arrow.right.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let item = appState.nextScheduleItem {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(timeText(for: item))
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(2)
                        if !item.isAllDay {
                            Text(relativeText(for: item))
                                .font(.caption)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            } else {
                Text(L10n.text(.noUpcomingSchedule, language: lang))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var todaySchedule: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(L10n.text(.todaySchedule, language: lang))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(appState.todayScheduleItems.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if appState.todayScheduleItems.isEmpty {
                Text(L10n.text(.noScheduleToday, language: lang))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appState.todayScheduleItems.prefix(5)) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(timeText(for: item))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(isPast(item) ? .tertiary : .secondary)
                            .frame(width: 48, alignment: .leading)
                        Text(item.title)
                            .font(.callout)
                            .foregroundStyle(isPast(item) ? .secondary : .primary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(L10n.text(.quickAdd, language: lang))
                .font(.subheadline.weight(.semibold))
            TextField(L10n.text(.scheduleTitlePlaceholder, language: lang), text: $appState.draftTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit { addSchedule() }
            HStack(spacing: 8) {
                DatePicker(
                    "",
                    selection: quickAddDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                Spacer()
                Button(L10n.text(.addSchedule, language: lang)) {
                    addSchedule()
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isWorking || appState.draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.top, 2)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                appState.recordManualRefresh()
                Task { await appState.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .help(L10n.text(.refreshWallpaper, language: lang))
            .disabled(appState.isWorking)

            Button(L10n.text(.manageSchedules, language: lang)) {
                openWindow(id: "settings")
            }
            Spacer()
            Button(L10n.text(.openSettings, language: lang)) {
                openWindow(id: "settings")
            }
            Button {
                appState.quit()
            } label: {
                Image(systemName: "power")
            }
            .help(L10n.text(.quit, language: lang))
        }
        .padding(.top, 2)
    }

    private var quickAddDate: Binding<Date> {
        Binding(
            get: { appState.composedDraftDate() ?? Date() },
            set: { date in
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                appState.draftYear = components.year ?? appState.draftYear
                appState.draftMonth = components.month ?? appState.draftMonth
                appState.draftDay = components.day ?? appState.draftDay
                appState.draftHour = components.hour ?? appState.draftHour
                appState.draftMinute = components.minute ?? appState.draftMinute
            }
        )
    }

    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = lang.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEE MMM d")
        return formatter.string(from: Date())
    }

    private func timeText(for item: CustomScheduleItem) -> String {
        guard !item.isAllDay else { return L10n.text(.allDay, language: lang) }
        let formatter = DateFormatter()
        formatter.locale = lang.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.startDate)
    }

    private func relativeText(for item: CustomScheduleItem) -> String {
        let minutes = Int(item.startDate.timeIntervalSinceNow / 60)
        if minutes >= 0 {
            return L10n.text(.inMinutes(minutes), language: lang)
        }
        return L10n.text(.startedMinutesAgo(abs(minutes)), language: lang)
    }

    private func isPast(_ item: CustomScheduleItem) -> Bool {
        !item.isAllDay && item.startDate < Date()
    }

    private func addSchedule() {
        Task {
            await appState.addScheduleItem()
            appState.prepareQuickAdd()
        }
    }
}

struct QuickScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        QuickScheduleView()
            .environmentObject(AppState())
    }
}
