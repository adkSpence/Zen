import Foundation
import SwiftData

@Model final class StreakState {
    var currentStreak: Int
    var longestStreak: Int
    var lastQualifyingDate: Date?

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastQualifyingDate: Date? = nil) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastQualifyingDate = lastQualifyingDate
    }
}
