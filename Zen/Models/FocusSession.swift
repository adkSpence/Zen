import Foundation
import SwiftData

@Model final class FocusSession {
    var startedAt: Date
    var endedAt: Date
    var plannedDurationSeconds: Int
    var actualDurationSeconds: Int
    var wasCompleted: Bool

    init(startedAt: Date,
         endedAt: Date,
         plannedDurationSeconds: Int,
         actualDurationSeconds: Int,
         wasCompleted: Bool) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.plannedDurationSeconds = plannedDurationSeconds
        self.actualDurationSeconds = actualDurationSeconds
        self.wasCompleted = wasCompleted
    }
}
