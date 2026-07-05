import Foundation
import SwiftData

struct SessionRecorder {
    static func record(
        startedAt: Date,
        endedAt: Date,
        plannedDurationSeconds: Int,
        wasCompleted: Bool,
        context: ModelContext
    ) {
        let actual = max(0, min(Int(endedAt.timeIntervalSince(startedAt)), plannedDurationSeconds))
        let session = FocusSession(
            startedAt: startedAt,
            endedAt: endedAt,
            plannedDurationSeconds: plannedDurationSeconds,
            actualDurationSeconds: actual,
            wasCompleted: wasCompleted
        )
        context.insert(session)
        try? context.save()
    }

    static func todaySeconds(from sessions: [FocusSession]) -> Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return sessions
            .filter { cal.startOfDay(for: $0.startedAt) == today }
            .reduce(0.0) { $0 + Double($1.actualDurationSeconds) }
    }
}
