import SwiftUI
import SwiftData

struct DailyGoalCard: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [DailyGoal]
    @Query private var sessions: [FocusSession]

    private var goal: DailyGoal { goals.first ?? DailyGoal() }

    private var todaySeconds: Double { SessionRecorder.todaySeconds(from: sessions) }
    private var todayHours: Double { todaySeconds / 3600 }
    private var progressFraction: Double {
        guard goal.targetHours > 0 else { return 0 }
        return min(1, todayHours / goal.targetHours)
    }
    private var goalMet: Bool { todayHours >= goal.targetHours }

    private var todayFormatted: String {
        let h = Int(todaySeconds) / 3600
        let m = (Int(todaySeconds) % 3600) / 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    private var goalFormatted: String {
        let totalMin = Int(goal.targetHours * 60)
        let h = totalMin / 60
        let m = totalMin % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: "Daily Goal")

                Spacer(minLength: 18)

                // Main progress display
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        AnimatedNumber(value: todayFormatted)
                            .font(.displayRounded(size: 44))
                            .foregroundStyle(goalMet ? Color.accentFocus : Color.textPrimary)

                        Text("of \(goalFormatted) goal")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if goalMet {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.accentFocus)
                            .transition(.scale(scale: 0.5).combined(with: .opacity))
                    } else {
                        Text("\(Int(progressFraction * 100))%")
                            .font(.displayRounded(size: 32, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .animation(.focusDefault, value: goalMet)

                Spacer(minLength: 20)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 8)
                        Capsule()
                            .fill(goalMet ? Color.accentFocus : Color.accentFocus.opacity(0.7))
                            .frame(width: max(0, geo.size.width * progressFraction), height: 8)
                            .animation(.progressBar, value: progressFraction)
                    }
                }
                .frame(height: 8)

                Spacer(minLength: 20)

                // Goal adjuster
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's target")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                        Text(goalFormatted)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button {
                            goal.targetHours = max(0.5, goal.targetHours - 0.5)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.07), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Decrease goal")

                        Button {
                            goal.targetHours = min(12, goal.targetHours + 0.5)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.07), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Increase goal")
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Daily Goal card, \(todayFormatted) focused of \(goalFormatted) goal")
    }
}
