import Foundation
import SwiftData

@Observable
final class StreakViewModel {

    /// Evaluates streak logic against current sessions and persists changes.
    /// Call after any session completes and on app launch / midnight rollover.
    func evaluate(sessions: [FocusSession], goal: DailyGoal, streak: StreakState, context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let todaySecs = SessionRecorder.todaySeconds(from: sessions)
        let goalSecs = goal.targetHours * 3600

        // Check for broken streak (a full day passed without qualifying)
        if let last = streak.lastQualifyingDate {
            let lastDay = cal.startOfDay(for: last)
            let daysSince = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if daysSince > 1 {
                streak.currentStreak = 0
            }
        }

        // Check if today qualifies
        guard todaySecs >= goalSecs else { return }

        if let last = streak.lastQualifyingDate {
            let lastDay = cal.startOfDay(for: last)
            if lastDay == today {
                return // already counted today
            }
            let daysSince = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            streak.currentStreak = daysSince == 1 ? streak.currentStreak + 1 : 1
        } else {
            streak.currentStreak = 1
        }

        streak.longestStreak = max(streak.currentStreak, streak.longestStreak)
        streak.lastQualifyingDate = today
        try? context.save()
    }

    func isAtRisk(streak: StreakState, sessions: [FocusSession], goal: DailyGoal) -> Bool {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: .now)
        guard hour >= 18 else { return false }
        let todaySecs = SessionRecorder.todaySeconds(from: sessions)
        return todaySecs < goal.targetHours * 3600
    }
}
