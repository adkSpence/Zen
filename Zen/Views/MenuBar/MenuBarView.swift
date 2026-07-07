import SwiftUI
import SwiftData

// MARK: - Dropdown panel

struct MenuBarPanel: View {
    @Environment(AppState.self) private var appState
    @Query private var settingsAll: [TimerSettings]
    @Query private var sessions: [FocusSession]
    @Query private var goals: [DailyGoal]

    private var vm: TimerViewModel { appState.timerVM }
    private var settings: TimerSettings { settingsAll.first ?? TimerSettings() }
    private var goal: DailyGoal { goals.first ?? DailyGoal() }

    var body: some View {
        VStack(spacing: 0) {
            // Mode label
            Text(vm.mode.label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(1.5)
                .padding(.top, 18)

            // Live countdown
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let remaining = vm.remainingSeconds(at: ctx.date)
                Text(formatMenuTime(remaining))
                    .font(.system(size: 52, weight: .light, design: .rounded).monospacedDigit())
                    .foregroundStyle(vm.runState == .paused ? Color.secondary : vm.mode.accentColor)
                    .contentTransition(.numericText(countsDown: true))
                    .padding(.vertical, 10)
            }

            // Controls
            HStack(spacing: 16) {
                CircleButton(icon: "arrow.counterclockwise", size: 36) {
                    vm.reset(settings: settings)
                }

                CircleButton(icon: vm.isRunning ? "pause.fill" : "play.fill", size: 52,
                             tint: vm.mode.accentColor, prominent: true) {
                    vm.toggleStartPause(settings: settings)
                }

                CircleButton(icon: "forward.end", size: 36) {
                    vm.skip(settings: settings)
                }
            }
            .padding(.bottom, 18)

            Divider()

            Button {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
            } label: {
                Text("Open Zen")
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .frame(width: 220)
    }
}

// MARK: - Helpers

private struct CircleButton: View {
    let icon: String
    let size: CGFloat
    var tint: Color = .secondary
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.35))
                .frame(width: size, height: size)
                .background(prominent ? tint : Color.primary.opacity(0.08),
                            in: Circle())
                .foregroundStyle(prominent ? .white : tint)
        }
        .buttonStyle(.plain)
    }
}

private func formatMenuTime(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds))
    return String(format: "%02d:%02d", total / 60, total % 60)
}
