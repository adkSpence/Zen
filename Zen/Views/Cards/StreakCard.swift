import SwiftUI
import SwiftData

struct StreakCard: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var streaks: [StreakState]
    @Query private var goals: [DailyGoal]
    @Query private var sessions: [FocusSession]

    private var streak: StreakState { streaks.first ?? StreakState() }
    private var goal: DailyGoal { goals.first ?? DailyGoal() }

    @State private var flameScale: CGFloat = 1.0

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                CardHeader(title: "Streak")

                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.accentStreakStart, .accentStreakEnd],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .scaleEffect(flameScale)
                        .symbolEffect(
                            .pulse,
                            options: reduceMotion ? .default : .repeating,
                            isActive: streak.currentStreak >= 3 && !reduceMotion
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            AnimatedNumber(value: "\(streak.currentStreak)")
                                .font(.displayRounded(size: 64))
                                .foregroundStyle(Color.textPrimary)
                        }
                        Text("day streak")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if let last = streak.lastQualifyingDate {
                    HStack {
                        Text("Last recorded: \(last, format: .dateTime.month(.abbreviated).day())")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if appState.streakVM.isAtRisk(streak: streak, sessions: sessions, goal: goal) {
                            Text("· Don't break it today")
                                .font(.caption)
                                .foregroundStyle(Color.accentFocus.opacity(0.8))
                        }
                    }
                }

                HStack {
                    Spacer()
                    Text("Longest: \(streak.longestStreak) days")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .onAppear { evaluateStreak() }
        .accessibilityLabel("Streak card, \(streak.currentStreak) day streak")
    }

    private func evaluateStreak() {
        appState.streakVM.evaluate(
            sessions: sessions,
            goal: goal,
            streak: streak,
            context: modelContext
        )
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { flameScale = 1.15 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { flameScale = 1.0 }
        }
    }
}
