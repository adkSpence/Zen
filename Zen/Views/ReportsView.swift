import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(AppState.self) private var appState
    @Query private var sessions: [FocusSession]

    private var vm: ChartViewModel { appState.chartVM }
    private var bars: [DayBar] { vm.bars(from: sessions) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Expanded weekly chart
                WeeklyChartCard(chartHeight: 220)
                    .frame(maxWidth: .infinity)

                // Session summary row
                HStack(spacing: 16) {
                    SummaryTile(
                        label: "Week Total",
                        value: vm.weeklyTotal(bars: bars),
                        icon: "clock.fill"
                    )
                    SummaryTile(
                        label: "Daily Average",
                        value: vm.dailyAverage(bars: bars),
                        icon: "chart.bar.fill"
                    )
                    SummaryTile(
                        label: "Active Days",
                        value: "\(bars.filter { $0.hours > 0 }.count) / 7",
                        icon: "calendar"
                    )
                }

                // Session history
                SessionHistoryCard(sessions: sessions)
            }
            .padding(20)
        }
        .background(Color.bgBase.ignoresSafeArea())
    }
}

// MARK: - Summary Tile

struct SummaryTile: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentFocus)
                Spacer(minLength: 4)
                Text(value)
                    .font(.displayRounded(size: 26, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Session History

struct SessionHistoryCard: View {
    let sessions: [FocusSession]

    private var recent: [FocusSession] {
        sessions
            .filter { $0.wasCompleted }
            .sorted { $0.startedAt > $1.startedAt }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: "Session History")

                if recent.isEmpty {
                    Text("No completed sessions yet")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 0) {
                        ForEach(recent) { session in
                            SessionRow(session: session)
                            if session.id != recent.last?.id {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct SessionRow: View {
    let session: FocusSession

    private var duration: String {
        let m = session.actualDurationSeconds / 60
        let s = session.actualDurationSeconds % 60
        if s == 0 { return "\(m)m" }
        return "\(m)m \(s)s"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.startedAt, format: .dateTime.weekday(.wide).month().day())
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Text(session.startedAt, format: .dateTime.hour().minute())
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(duration)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.accentFocus)
        }
        .padding(.vertical, 8)
    }
}
