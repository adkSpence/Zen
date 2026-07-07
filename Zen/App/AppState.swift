import SwiftUI
import SwiftData

@Observable
final class AppState {
    let timerVM = TimerViewModel()
    let streakVM = StreakViewModel()
    let chartVM = ChartViewModel()
    let notifications = NotificationService.shared
    let menuBar = MenuBarManager()

    func setup(context: ModelContext, settings: TimerSettings) {
        timerVM.setup(context: context, settings: settings)
        notifications.requestAuthorization()

        // Evaluate streak on launch (handles overnight resets)
        evaluateStreak(context: context)

        // Wire direct callback: fires the instant a focus session is saved,
        // bypassing SwiftUI's onChange timing entirely.
        timerVM.onFocusSessionRecorded = { [weak self] in
            self?.evaluateStreak(context: context)
        }

        menuBar.setup(appState: self, container: context.container)
    }

    func evaluateStreak(context: ModelContext) {
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        let goals    = (try? context.fetch(FetchDescriptor<DailyGoal>())) ?? []
        let streaks  = (try? context.fetch(FetchDescriptor<StreakState>())) ?? []
        guard let goal = goals.first, let streak = streaks.first else { return }
        streakVM.evaluate(sessions: sessions, goal: goal, streak: streak, context: context)
    }
}
