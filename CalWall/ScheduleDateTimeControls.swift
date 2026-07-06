import SwiftUI

struct ScheduleDateTimeControls: View {
    @Binding var year: Int
    @Binding var month: Int
    @Binding var day: Int
    @Binding var hour: Int
    @Binding var minute: Int
    let showsTime: Bool
    let language: AppLanguage

    private var dayRange: ClosedRange<Int> {
        1...maxDays(in: year, month: month)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                pickerColumn(
                    title: L10n.text(.scheduleYear, language: language),
                    selection: $year,
                    values: Array((yearRange.lowerBound...yearRange.upperBound))
                )
                pickerColumn(
                    title: L10n.text(.scheduleMonth, language: language),
                    selection: $month,
                    values: Array(1...12)
                )
                pickerColumn(
                    title: L10n.text(.scheduleDay, language: language),
                    selection: $day,
                    values: Array(dayRange)
                )
            }

            if showsTime {
                HStack(spacing: 8) {
                    pickerColumn(
                        title: L10n.text(.scheduleHour, language: language),
                        selection: $hour,
                        values: Array(0...23),
                        width: 72
                    )
                    Text(":")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 18)
                    pickerColumn(
                        title: L10n.text(.scheduleMinute, language: language),
                        selection: $minute,
                        values: Array(stride(from: 0, to: 60, by: 5)),
                        width: 72
                    )
                }
            }
        }
        .onChange(of: year) { _, _ in clampDay() }
        .onChange(of: month) { _, _ in clampDay() }
    }

    private var yearRange: ClosedRange<Int> {
        let current = Calendar.current.component(.year, from: Date())
        return (current - 1)...(current + 2)
    }

    private func pickerColumn(title: String, selection: Binding<Int>, values: [Int], width: CGFloat = 88) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(formatValue(value)).tag(value)
                }
            }
            .pickerStyle(.menu)
            .frame(width: width)
        }
    }

    private func formatValue(_ value: Int) -> String {
        if value < 10, L10n.text(.scheduleHour, language: language) != L10n.text(.scheduleYear, language: language) {
            return String(format: "%02d", value)
        }
        return "\(value)"
    }

    private func clampDay() {
        let maxDay = maxDays(in: year, month: month)
        if day > maxDay {
            day = maxDay
        }
    }

    private func maxDays(in year: Int, month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let calendar = Calendar.current
        guard let date = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 31
        }
        return range.count
    }
}
