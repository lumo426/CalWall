import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("CalWall")
                        .font(.title2.weight(.semibold))
                    Text("Minimal calendar wallpaper")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(appState.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Wallpaper View")
                    .font(.headline)
                Picker("Wallpaper View", selection: $appState.selectedPerspective) {
                    ForEach(CalendarPerspective.allCases) { perspective in
                        Text(perspective.title).tag(perspective)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance")
                    .font(.headline)
                Picker("Appearance", selection: $appState.themeFamily) {
                    ForEach(WallpaperThemeFamily.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .disabled(appState.isWorking)

                if appState.themeFamily.supportsBlueVariant {
                    Picker("Blue Variant", selection: $appState.blueVariant) {
                        ForEach(BlueThemeVariant.allCases) { variant in
                            Text(variant.title).tag(variant)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .disabled(appState.isWorking)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Custom Schedule")
                    .font(.headline)
                Text("Syncs across Day, Week, Month, and Year wallpapers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $appState.customText)
                        .font(.system(.callout, design: .rounded))
                        .frame(height: 118)
                        .padding(5)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    if appState.customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(CalendarPerspective.customSchedulePlaceholder)
                            .font(.caption)
                            .foregroundStyle(.secondary.opacity(0.72))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
                Button {
                    Task { await appState.saveCustomTextAndRefresh() }
                } label: {
                    Label("Save Custom Schedule", systemImage: "text.badge.plus")
                }
                .disabled(appState.isWorking)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appState.selectedPerspective.scheduleTitle)
                    .font(.headline)

                if appState.events.isEmpty {
                    Text("No custom events in this view.")
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
                        Text("+ \(appState.events.count - 5) more item(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    Task { await appState.refresh() }
                } label: {
                    Label(appState.isWorking ? "Updating…" : "Refresh Wallpaper", systemImage: "arrow.clockwise")
                }
                .disabled(appState.isWorking)

                if let url = appState.lastWallpaperURL {
                    Button("Reveal Image") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Quit") { appState.quit() }
            }
        }
        .padding(22)
        .frame(width: 480)
    }

    private func timeLabel(for event: CalendarEvent) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current

        if event.isAllDay {
            switch appState.selectedPerspective {
            case .day:
                return "All day"
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
