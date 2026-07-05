import SwiftUI
import SwiftData
import Charts

struct WeeklyChartCard: View {
    @Environment(AppState.self) private var appState
    @Query private var sessions: [FocusSession]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var chartHeight: CGFloat = 160

    @State private var animatedHeights: [Date: Double] = [:]

    private var vm: ChartViewModel { appState.chartVM }
    private var bars: [DayBar] { vm.bars(from: sessions) }
    private var maxHours: Double { max(bars.map(\.hours).max() ?? 0, 1) }

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                CardHeader(title: "This Week")

                Chart(bars) { bar in
                    BarMark(
                        x: .value("Day", bar.weekdayShort),
                        y: .value("Hours", animatedHeights[bar.date] ?? 0)
                    )
                    .foregroundStyle(
                        bar.isToday
                            ? Color.accentFocus
                            : Color.accentFocus.opacity(0.45)
                    )
                    .cornerRadius(5)
                }
                .frame(height: chartHeight)
                .chartYScale(domain: 0...(maxHours * 1.25))
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let str = value.as(String.self),
                               let bar = bars.first(where: { $0.weekdayShort == str }) {
                                Text(str)
                                    .font(.caption2)
                                    .fontWeight(bar.isToday ? .bold : .regular)
                                    .foregroundStyle(bar.isToday ? Color.accentFocus : Color.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Divider()

                HStack {
                    Label("Total", systemImage: "sum")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(vm.weeklyTotal(bars: bars))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("Daily avg", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(vm.dailyAverage(bars: bars))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { animateBars() }
        .onChange(of: sessions.count) { animateBars() }
    }

    func animateBars() {
        if reduceMotion {
            for bar in bars { animatedHeights[bar.date] = bar.hours }
            return
        }
        for (i, bar) in bars.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.04) {
                withAnimation(.chartBar) { animatedHeights[bar.date] = bar.hours }
            }
        }
    }
}
