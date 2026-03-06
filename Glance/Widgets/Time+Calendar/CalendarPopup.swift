import EventKit
import SwiftUI

struct CalendarPopup: View {
    let calendarManager: CalendarManager
    @ObservedObject var configProvider: ConfigProvider
    @ObservedObject var configManager = ConfigManager.shared
    var appearance: AppearanceConfig { configManager.config.appearance }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(currentMonthYear)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.bottom, 20)

            // Weekday headers
            WeekdayHeaderView(appearance: appearance)

            // Calendar grid
            CalendarDaysView(
                weeks: weeks,
                currentYear: currentYear,
                currentMonth: currentMonth,
                appearance: appearance
            )

            // Events
            if !calendarManager.todaysEvents.isEmpty || !calendarManager.tomorrowsEvents.isEmpty {
                Divider()
                    .background(appearance.foregroundColor.opacity(0.15))
                    .padding(.vertical, 16)

                EventListView(
                    todaysEvents: calendarManager.todaysEvents,
                    tomorrowsEvents: calendarManager.tomorrowsEvents,
                    appearance: appearance
                )
            }
        }
        .padding(24)
    }
}

// MARK: - Calendar Helpers

private var currentMonthYear: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "LLLL yyyy"
    return formatter.string(from: Date()).capitalized
}

private var currentMonth: Int {
    Calendar.current.component(.month, from: Date())
}

private var currentYear: Int {
    Calendar.current.component(.year, from: Date())
}

private var calendarDays: [Int?] {
    let calendar = Calendar.current
    let date = Date()
    guard
        let range = calendar.range(of: .day, in: .month, for: date),
        let firstOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: date)
        )
    else {
        return []
    }
    let startOfMonthWeekday = calendar.component(.weekday, from: firstOfMonth)
    let blanks = (startOfMonthWeekday - calendar.firstWeekday + 7) % 7
    var days: [Int?] = Array(repeating: nil, count: blanks)
    days.append(contentsOf: range.map { $0 })
    return days
}

private var weeks: [[Int?]] {
    var days = calendarDays
    let remainder = days.count % 7
    if remainder != 0 {
        days.append(contentsOf: Array(repeating: nil, count: 7 - remainder))
    }
    return stride(from: 0, to: days.count, by: 7).map {
        Array(days[$0..<min($0 + 7, days.count)])
    }
}

// MARK: - Weekday Header

private struct WeekdayHeaderView: View {
    let appearance: AppearanceConfig

    var body: some View {
        let calendar = Calendar.current
        let weekdaySymbols = calendar.shortWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1
        let reordered = Array(
            weekdaySymbols[firstWeekdayIndex...]
                + weekdaySymbols[..<firstWeekdayIndex]
        )
        let referenceDate = DateComponents(
            calendar: calendar, year: 2020, month: 12, day: 13
        ).date!
        let referenceDays = (0..<7).map { i in
            calendar.date(byAdding: .day, value: i, to: referenceDate)!
        }

        HStack {
            ForEach(reordered.indices, id: \.self) { i in
                let originalIndex = (i + firstWeekdayIndex) % 7
                let isWeekend = calendar.isDateInWeekend(referenceDays[originalIndex])

                Text(reordered[i])
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 30)
                    .opacity(isWeekend ? 0.4 : 0.6)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Calendar Days

private struct CalendarDaysView: View {
    let weeks: [[Int?]]
    let currentYear: Int
    let currentMonth: Int
    let appearance: AppearanceConfig

    var body: some View {
        let calendar = Calendar.current
        VStack(spacing: 6) {
            ForEach(weeks.indices, id: \.self) { weekIndex in
                HStack(spacing: 6) {
                    ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                        if let day = weeks[weekIndex][dayIndex] {
                            let date = calendar.date(
                                from: DateComponents(
                                    year: currentYear, month: currentMonth, day: day
                                )
                            )!
                            let isWeekend = calendar.isDateInWeekend(date)
                            let today = isToday(day: day)

                            ZStack {
                                if today {
                                    Circle()
                                        .fill(appearance.accentColor)
                                        .frame(width: 30, height: 30)
                                }
                                Text("\(day)")
                                    .font(.system(size: 13, weight: today ? .bold : .regular))
                                    .foregroundStyle(
                                        today
                                            ? todayTextColor
                                            : appearance.foregroundColor.opacity(isWeekend ? 0.4 : 1.0)
                                    )
                                    .frame(width: 30, height: 30)
                            }
                        } else {
                            Color.clear.frame(width: 30, height: 30)
                        }
                    }
                }
            }
        }
    }

    /// Pick a text color that contrasts with the accent circle.
    /// White/light accent → black text. Colored/dark accent → white text.
    private var todayTextColor: Color {
        // Resolve NSColor to check luminance
        let ns = NSColor(appearance.accentColor)
        guard let rgb = ns.usingColorSpace(.sRGB) else { return .black }
        let luminance = 0.299 * rgb.redComponent + 0.587 * rgb.greenComponent + 0.114 * rgb.blueComponent
        return luminance > 0.6 ? .black : .white
    }

    func isToday(day: Int) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        if let dateFromDay = calendar.date(
            from: DateComponents(year: components.year, month: components.month, day: day)
        ) {
            return calendar.isDateInToday(dateFromDay)
        }
        return false
    }
}

// MARK: - Event List

private struct EventListView: View {
    let todaysEvents: [EKEvent]
    let tomorrowsEvents: [EKEvent]
    let appearance: AppearanceConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !todaysEvents.isEmpty {
                eventSection(title: NSLocalizedString("TODAY", comment: "").uppercased(), events: todaysEvents)
            }
            if !tomorrowsEvents.isEmpty {
                eventSection(title: NSLocalizedString("TOMORROW", comment: "").uppercased(), events: tomorrowsEvents)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func eventSection(title: String, events: [EKEvent]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .opacity(0.5)
            ForEach(events, id: \.eventIdentifier) { event in
                EventRow(event: event, appearance: appearance)
            }
        }
    }
}

private struct EventRow: View {
    let event: EKEvent
    let appearance: AppearanceConfig

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(event.calendar.cgColor))
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(getEventTime(event))
                    .font(.caption)
                    .opacity(0.6)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(event.calendar.cgColor).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    func getEventTime(_ event: EKEvent) -> String {
        if event.isAllDay {
            return NSLocalizedString("ALL_DAY", comment: "")
        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        let start = formatter.string(from: event.startDate).replacing(":00", with: "")
        let end = formatter.string(from: event.endDate).replacing(":00", with: "")
        return "\(start) — \(end)"
    }
}
