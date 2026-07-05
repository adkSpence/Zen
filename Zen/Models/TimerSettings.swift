import SwiftData

@Model final class TimerSettings {
    var focusMinutes: Int
    var breakMinutes: Int
    var longBreakMinutes: Int
    var sessionsBeforeLongBreak: Int

    init(focusMinutes: Int = 25,
         breakMinutes: Int = 5,
         longBreakMinutes: Int = 15,
         sessionsBeforeLongBreak: Int = 4) {
        self.focusMinutes = focusMinutes
        self.breakMinutes = breakMinutes
        self.longBreakMinutes = longBreakMinutes
        self.sessionsBeforeLongBreak = sessionsBeforeLongBreak
    }
}
