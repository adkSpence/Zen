# Zen

A minimal macOS focus timer app built with SwiftUI and SwiftData.

## Features

- **Pomodoro-style timer** — configurable focus, short break, and long break durations
- **Daily goal tracking** — set a daily focus target and watch your progress
- **Streak tracking** — maintain a daily focus streak
- **Focus list** — lightweight task list to capture what you're working on
- **Reports tab** — weekly chart, daily averages, active days, and a session history log

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later

## Getting Started

1. Clone the repo
2. Open `Zen.xcodeproj` in Xcode
3. Select the **Zen** scheme and your Mac as the target
4. Press `⌘R` to build and run

No external dependencies — the project uses only Apple frameworks (SwiftUI, SwiftData, UserNotifications).

## Project Structure

```
Zen/
├── App/            # App entry point and shared AppState
├── Models/         # SwiftData models (FocusSession, TimerSettings, DailyGoal, …)
├── ViewModels/     # ChartViewModel, TimerViewModel, StreakViewModel
├── Views/
│   ├── Cards/      # TimerCard, DailyGoalCard, StreakCard, FocusListCard, WeeklyChartCard
│   └── Components/ # Reusable views (Card, CircularTimerRing, AnimatedNumber)
├── Services/       # SessionRecorder, NotificationService
└── Theme/          # Colors, Typography, Motion constants
```
