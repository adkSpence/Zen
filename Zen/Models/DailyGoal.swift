import SwiftData

@Model final class DailyGoal {
    var targetHours: Double

    init(targetHours: Double = 4.0) {
        self.targetHours = targetHours
    }
}
