import SwiftUI
import SwiftData

struct TimerCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var settingsAll: [TimerSettings]
    @Query private var sessions: [FocusSession]
    @Query private var goals: [DailyGoal]

    @State private var pulseScale: CGFloat = 1.0
    @State private var particles: [ParticleDot] = []

    private var vm: TimerViewModel { appState.timerVM }
    private var settings: TimerSettings { settingsAll.first ?? TimerSettings() }
    private var goal: DailyGoal { goals.first ?? DailyGoal() }

    var body: some View {
        CardContainer {
            VStack(spacing: 0) {
                CardHeader(title: "Focus Timer",
                           trailing: AnyView(settingsButton))

                if vm.showSettingsPanel {
                    settingsPanel
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 12)
                }

                Spacer(minLength: 20)

                TimelineView(.animation) { ctx in
                    let now = ctx.date
                    let remaining = vm.remainingSeconds(at: now)
                    let progress = vm.progressFraction(at: now)

                    ZStack {
                        CircularTimerRing(
                            progress: progress,
                            color: vm.mode.accentColor,
                            diameter: 280
                        )
                        .scaleEffect(pulseScale)

                        // Particle burst
                        ForEach(particles) { p in
                            Circle()
                                .fill(vm.mode.accentColor.opacity(p.opacity))
                                .frame(width: 6, height: 6)
                                .offset(x: p.x, y: p.y)
                        }

                        VStack(spacing: 6) {
                            AnimatedNumber(value: formatTime(remaining))
                                .font(.timerDigits(size: 56))
                                .foregroundStyle(Color.textPrimary)
                                .accessibilityValue(accessibilityTimeLabel(remaining))

                            Text(vm.mode.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                                .animation(.modeTransition, value: vm.mode.label)
                        }
                    }
                    .onChange(of: remaining) { _, new in
                        if new <= 0 && vm.runState == .running {
                            vm.timerElapsed(settings: settings, sessions: sessions, goal: goal)
                            triggerCompletion()
                        }
                    }
                }

                Spacer(minLength: 20)

                // Notification banner
                if !appState.notifications.isAuthorized {
                    notificationBanner
                        .padding(.bottom, 8)
                }

                controlButtons
            }
        }
        .onAppear {
            vm.setup(context: modelContext, settings: settings)
        }
        .task(id: vm.runID) {
            guard vm.runState == .running else { return }
            let remaining = vm.remainingSeconds()
            guard remaining > 0 else { return }
            try? await Task.sleep(for: .seconds(remaining + 0.05))
            if !Task.isCancelled && vm.runState == .running {
                vm.timerElapsed(settings: settings, sessions: sessions, goal: goal)
                triggerCompletion()
            }
        }
        .onChange(of: vm.didJustComplete) { _, fired in
            guard fired else { return }
            vm.didJustComplete = false
        }
        .keyboardShortcut(" ", modifiers: [])
    }

    // MARK: - Subviews

    private var settingsButton: some View {
        Button {
            withAnimation(.focusDefault) { vm.showSettingsPanel.toggle() }
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Timer settings")
    }

    private var settingsPanel: some View {
        VStack(spacing: 12) {
            Divider()
            Group {
                StepperRow(label: "Focus", value: Binding(
                    get: { settings.focusMinutes },
                    set: { settings.focusMinutes = $0; vm.applySettings(settings) }
                ), range: 5...90, step: 5, unit: "min")

                StepperRow(label: "Short break", value: Binding(
                    get: { settings.breakMinutes },
                    set: { settings.breakMinutes = $0 }
                ), range: 1...30, step: 1, unit: "min")

                StepperRow(label: "Long break", value: Binding(
                    get: { settings.longBreakMinutes },
                    set: { settings.longBreakMinutes = $0 }
                ), range: 5...60, step: 5, unit: "min")

                StepperRow(label: "Sessions before long break", value: Binding(
                    get: { settings.sessionsBeforeLongBreak },
                    set: { settings.sessionsBeforeLongBreak = $0 }
                ), range: 2...8, step: 1, unit: "")
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Reset
            Button {
                vm.reset(settings: settings)
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Reset timer")
            .keyboardShortcut("r", modifiers: .command)

            // Start / Pause
            Button {
                vm.toggleStartPause(settings: settings)
            } label: {
                Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .symbolEffect(.bounce, options: .speed(1.2), value: vm.isRunning)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 120, height: 44)
                    .background(vm.mode.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(vm.isRunning ? "Pause timer" : "Start timer")

            // Skip
            Button {
                vm.skip(settings: settings)
            } label: {
                Image(systemName: "forward.end")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Skip to next interval")
            .keyboardShortcut(.rightArrow, modifiers: .command)
        }
        .padding(.top, 16)
    }

    private var notificationBanner: some View {
        HStack {
            Image(systemName: "bell.slash")
                .foregroundStyle(.secondary)
            Text("Notifications off — enable in System Settings to get alerts.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Open Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentFocus)
        }
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func triggerCompletion() {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            pulseScale = 1.04
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                pulseScale = 1.0
            }
        }
        fireParticles()
    }

    private func fireParticles() {
        particles = (0..<8).map { i in
            let angle = Double(i) / 8.0 * .pi * 2
            return ParticleDot(
                id: UUID(),
                x: cos(angle) * 160,
                y: sin(angle) * 160,
                opacity: 0
            )
        }
        withAnimation(.easeOut(duration: 0.6)) {
            particles = particles.map { ParticleDot(id: $0.id, x: $0.x, y: $0.y, opacity: 0) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { particles = [] }
    }

    private func accessibilityTimeLabel(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return "\(m) minutes \(s) seconds remaining"
    }
}

// MARK: - Supporting types

struct ParticleDot: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
}

struct StepperRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Stepper(unit.isEmpty ? "\(value)" : "\(value) \(unit)", value: $value, in: range, step: step)
                .labelsHidden()
            Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                .font(.system(size: 13, weight: .medium))
                .frame(minWidth: 50, alignment: .trailing)
        }
    }
}
