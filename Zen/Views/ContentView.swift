import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query private var settingsAll: [TimerSettings]
    @Query private var goalsAll: [DailyGoal]
    @Query private var streaksAll: [StreakState]

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
        }
        .background(Color.bgBase.ignoresSafeArea())
        .onAppear {
            ensureDefaults()
            if let s = settingsAll.first {
                appState.setup(context: modelContext, settings: s)
            }
        }
    }

    private func ensureDefaults() {
        if settingsAll.isEmpty { modelContext.insert(TimerSettings()) }
        if goalsAll.isEmpty    { modelContext.insert(DailyGoal()) }
        if streaksAll.isEmpty  { modelContext.insert(StreakState()) }
        try? modelContext.save()
    }
}

// MARK: - Home

struct HomeView: View {
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 16) {
                    TimerCard()
                        .frame(maxWidth: .infinity)

                    if geo.size.width >= 880 {
                        HStack(alignment: .top, spacing: 16) {
                            DailyGoalCard()
                            StreakCard()
                        }
                        FocusListCard()
                            .frame(maxWidth: .infinity)
                    } else {
                        DailyGoalCard()
                        StreakCard()
                        FocusListCard()
                    }
                }
                .padding(20)
            }
        }
        .background(Color.bgBase.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [
            TimerSettings.self, DailyGoal.self,
            FocusSession.self, StreakState.self, FocusListItem.self
        ], inMemory: true)
}
