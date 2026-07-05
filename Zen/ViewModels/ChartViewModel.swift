import Foundation

struct DayBar: Identifiable {
    let id: Date
    let date: Date
    let weekdayShort: String  // "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
    let hours: Double
    let isToday: Bool
}

@Observable
final class ChartViewModel {

    func bars(from sessions: [FocusSession]) -> [DayBar] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        return (0..<7).reversed().map { offset -> DayBar in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let seconds = sessions
                .filter { cal.startOfDay(for: $0.startedAt) == day }
                .reduce(0.0) { $0 + Double($1.actualDurationSeconds) }
            let short = cal.shortWeekdaySymbols[cal.component(.weekday, from: day) - 1]
            return DayBar(id: day, date: day, weekdayShort: short,
                          hours: seconds / 3600, isToday: day == today)
        }
    }

    func weeklyTotal(bars: [DayBar]) -> String {
        formatHours(bars.reduce(0.0) { $0 + $1.hours })
    }

    func dailyAverage(bars: [DayBar]) -> String {
        formatHours(bars.reduce(0.0) { $0 + $1.hours } / Double(bars.count))
    }

    private func formatHours(_ h: Double) -> String {
        let totalMin = Int(h * 60)
        let hrs = totalMin / 60
        let mins = totalMin % 60
        if hrs == 0 { return "\(mins)m" }
        if mins == 0 { return "\(hrs)h" }
        return "\(hrs)h \(mins)m"
    }
}
