import SwiftUI
import SwiftData

@main
struct ZenApp: App {
    @State private var appState = AppState()

    let container: ModelContainer = {
        let schema = Schema([
            TimerSettings.self,
            DailyGoal.self,
            FocusSession.self,
            StreakState.self,
            FocusListItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(container)
        .defaultSize(width: 1100, height: 780)
        .windowResizability(.contentMinSize)

    }
}
