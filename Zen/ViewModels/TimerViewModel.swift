import SwiftUI
import SwiftData

enum TimerMode {
    case focus, shortBreak, longBreak

    var label: String {
        switch self {
        case .focus:      return "Focus"
        case .shortBreak: return "Break"
        case .longBreak:  return "Long Break"
        }
    }

    var accentColor: Color {
        switch self {
        case .focus:      return .accentFocus
        case .shortBreak: return .accentBreak
        case .longBreak:  return .accentBreakLong
        }
    }
}

enum TimerRunState {
    case idle, running, paused, completed
}

@Observable
final class TimerViewModel {
    // Engine state
    var mode: TimerMode = .focus
    var runState: TimerRunState = .idle
    var plannedDurationSeconds: Int = 25 * 60
    var sessionStartedAt: Date = .now
    var pausedAt: Date? = nil
    var accumulatedPauseDuration: TimeInterval = 0
    var completedFocusCount: Int = 0

    // Run ID changes every start/resume so .task(id:) reschedules the sleep
    var runID: UUID = UUID()

    // UI triggers
    var didJustComplete = false
    var showSettingsPanel = false

    // Injected after setup
    private var modelContext: ModelContext?
    private var sessionRecordStart: Date?

    /// Called immediately after a completed focus session is written to the store.
    /// AppState uses this to trigger streak evaluation while the context is still hot.
    var onFocusSessionRecorded: (() -> Void)?

    func setup(context: ModelContext, settings: TimerSettings) {
        modelContext = context
        applySettings(settings)
    }

    func applySettings(_ s: TimerSettings) {
        guard runState == .idle || runState == .completed else { return }
        plannedDurationSeconds = durationFor(mode: mode, settings: s)
    }

    // MARK: - Computed

    func remainingSeconds(at now: Date = .now) -> TimeInterval {
        switch runState {
        case .idle, .completed:
            return TimeInterval(plannedDurationSeconds)
        case .running:
            let elapsed = now.timeIntervalSince(sessionStartedAt) - accumulatedPauseDuration
            return max(0, TimeInterval(plannedDurationSeconds) - elapsed)
        case .paused:
            let elapsed = (pausedAt ?? now).timeIntervalSince(sessionStartedAt) - accumulatedPauseDuration
            return max(0, TimeInterval(plannedDurationSeconds) - elapsed)
        }
    }

    func progressFraction(at now: Date = .now) -> Double {
        guard plannedDurationSeconds > 0 else { return 0 }
        let elapsed = TimeInterval(plannedDurationSeconds) - remainingSeconds(at: now)
        return min(1, max(0, elapsed / TimeInterval(plannedDurationSeconds)))
    }

    var isRunning: Bool { runState == .running }

    // MARK: - Actions

    func toggleStartPause(settings: TimerSettings) {
        switch runState {
        case .idle, .completed:
            startFresh(settings: settings)
        case .running:
            pause()
        case .paused:
            resume()
        }
    }

    func reset(settings: TimerSettings) {
        recordIfNeeded(wasCompleted: false)
        sessionRecordStart = nil
        NotificationService.shared.cancelAll()
        runState = .idle
        pausedAt = nil
        accumulatedPauseDuration = 0
        plannedDurationSeconds = durationFor(mode: mode, settings: settings)
        runID = UUID()
    }

    func skip(settings: TimerSettings) {
        recordIfNeeded(wasCompleted: false)
        sessionRecordStart = nil
        NotificationService.shared.cancelAll()
        mode = nextMode(after: mode, settings: settings)
        runState = .idle
        pausedAt = nil
        accumulatedPauseDuration = 0
        plannedDurationSeconds = durationFor(mode: mode, settings: settings)
        runID = UUID()
    }

    /// Called from .task(id: runID) when the sleep elapses — timer reached zero.
    func timerElapsed(settings: TimerSettings, sessions: [FocusSession], goal: DailyGoal) {
        guard runState == .running else { return }
        let completingMode = mode
        let wasFocus = completingMode == .focus

        // Record + notify AppState for streak evaluation
        if wasFocus {
            recordIfNeeded(wasCompleted: true)
            completedFocusCount += 1
            onFocusSessionRecorded?()
        }
        sessionRecordStart = nil

        // Fire the end-of-interval notification
        let todaySecs = SessionRecorder.todaySeconds(from: sessions) + (wasFocus ? Double(plannedDurationSeconds) : 0)
        let goalMet   = todaySecs >= goal.targetHours * 3600
        if wasFocus {
            NotificationService.shared.scheduleFocusEnd(in: 0.5, goalMet: goalMet)
        } else {
            NotificationService.shared.scheduleBreakEnd(in: 0.5)
        }

        // Advance to next mode
        let nextMode = nextMode(after: completingMode, settings: settings)
        mode = nextMode
        plannedDurationSeconds = durationFor(mode: nextMode, settings: settings)
        didJustComplete = true
        pausedAt = nil
        accumulatedPauseDuration = 0

        // Auto-start rules:
        //   focus      ends → auto-start the break (short or long)
        //   short break ends → auto-start focus
        //   long break  ends → stay idle, let user decide when to re-focus
        let autoStart: Bool
        switch completingMode {
        case .focus, .shortBreak: autoStart = true
        case .longBreak:          autoStart = false
        }

        if autoStart {
            sessionStartedAt    = .now
            sessionRecordStart  = (nextMode == .focus) ? .now : nil
            runState            = .running
            scheduleNotification()
        } else {
            runState = .idle
        }

        runID = UUID()
    }

    // MARK: - Private

    private func startFresh(settings: TimerSettings) {
        sessionStartedAt = .now
        sessionRecordStart = .now
        accumulatedPauseDuration = 0
        pausedAt = nil
        runState = .running
        scheduleNotification()
        runID = UUID()
    }

    private func pause() {
        pausedAt = .now
        runState = .paused
        NotificationService.shared.cancelAll()
        runID = UUID()
    }

    private func resume() {
        if let p = pausedAt {
            accumulatedPauseDuration += Date.now.timeIntervalSince(p)
        }
        pausedAt = nil
        runState = .running
        scheduleNotification()
        runID = UUID()
    }

    private func scheduleNotification() {
        let remaining = remainingSeconds()
        if mode == .focus {
            NotificationService.shared.scheduleFocusEnd(in: remaining, goalMet: false)
        } else {
            NotificationService.shared.scheduleBreakEnd(in: remaining)
        }
    }

    private func recordIfNeeded(wasCompleted: Bool) {
        guard let start = sessionRecordStart, let ctx = modelContext else { return }
        guard runState == .running || runState == .paused else { return }
        SessionRecorder.record(
            startedAt: start,
            endedAt: .now,
            plannedDurationSeconds: plannedDurationSeconds,
            wasCompleted: wasCompleted,
            context: ctx
        )
    }

    private func durationFor(mode: TimerMode, settings: TimerSettings) -> Int {
        switch mode {
        case .focus:      return settings.focusMinutes * 60
        case .shortBreak: return settings.breakMinutes * 60
        case .longBreak:  return settings.longBreakMinutes * 60
        }
    }

    private func nextMode(after mode: TimerMode, settings: TimerSettings) -> TimerMode {
        switch mode {
        case .focus:
            let nextCount = completedFocusCount
            return nextCount > 0 && nextCount % settings.sessionsBeforeLongBreak == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }
}
