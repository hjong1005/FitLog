# FitLog — iOS Workout Tracker

A native SwiftUI iOS app to log, track, and review your gym workouts.

---

## Features

### 🏠 Home Screen
- Weekly workout count (Mon–Sun)
- Three stat squares: **Lifetime** · **Last Month** · **Weekly Streak**
- Recent workouts list

### 📋 History Screen
- **Day filter** — 7 circles (M T W T F S S); circles with a red outline have past workouts. Tap to show only workouts on that day of the week, grouped by month.
- **Weekly toggle** — groups all workouts into Mon–Sun week blocks, newest first. Current week highlighted with a red border.
- **Workout detail** — tap any card to see the full breakdown: exercise name, set-by-set reps and weight, max kg, total sets.

### ➕ New Workout Entry
- Set workout name and date (defaults to today)
- **📷 camera button** in the nav bar → Take Photo or Upload Image
- AI (Claude) analyses the image and extracts exercises automatically
- Review/edit the AI result before importing
- **+ button** (bottom-right) → adds a manual exercise row with columns: Name · Reps/Set · Weight (kg)
- Per-exercise "+ Add Set" for multiple sets with individual reps/weight

---

## Setup

### Requirements
- Xcode 15+
- iOS 17+ deployment target
- An Anthropic API key (for AI image scanning)

### Steps

1. **Open in Xcode**
   ```
   open FitLog.xcodeproj
   ```
   > If you don't have an `.xcodeproj` yet, create a new Xcode project named `FitLog`, select **SwiftUI App**, set **Core Data** checked, then replace the generated files with the ones in this folder.

2. **Add your API key**
   Open `Utilities/AIAnalysisService.swift` and replace:
   ```swift
   private let apiKey = "YOUR_ANTHROPIC_API_KEY"
   ```
   with your actual key from https://console.anthropic.com.

   > **Security tip**: For production, store the key in the iOS Keychain or load it from a server — never ship a hardcoded key in a public app.

3. **Core Data model**
   The `FitLog.xcdatamodeld` folder contains the model definition. Xcode will pick it up automatically. Three entities:
   - `WorkoutRecord` — id, name, date, createdAt
   - `ExerciseRecord` — id, name, order → belongs to WorkoutRecord
   - `SetRecord` — id, reps, weight, order → belongs to ExerciseRecord

4. **Build & Run**
   Select your device or simulator (iPhone 15 recommended) and press ▶.

---

## File Structure

```
FitLog/
├── FitLogApp.swift               # @main entry point
├── Info.plist                    # Camera + photo permissions
│
├── Models/
│   ├── FitLog.xcdatamodeld/     # Core Data schema
│   ├── CoreDataModels.swift     # NSManagedObject subclasses + extensions
│   └── PersistenceController.swift
│
├── ViewModels/
│   └── WorkoutStore.swift       # Data access, stats helpers, draft models
│
├── Views/
│   ├── ContentView.swift        # TabView root (Home / History)
│   ├── HomeView.swift           # Weekly hero, stat squares, recent list
│   ├── HistoryView.swift        # Day filter, weekly view, grouped list
│   ├── WorkoutRowCard.swift     # Shared card component
│   ├── WorkoutDetailView.swift  # Full workout breakdown
│   └── NewWorkoutView.swift     # Entry form + camera + AI scan sheet
│
└── Utilities/
    ├── AIAnalysisService.swift  # Anthropic API call + JSON parsing
    └── DesignSystem.swift       # Colors, badges, reusable components
```

---

## Extending the App

| Want to add…            | Where to look                        |
|-------------------------|--------------------------------------|
| iCloud sync             | `PersistenceController` — enable `NSPersistentCloudKitContainer` |
| Exercise history graph  | Add a new `ProgressView` using `WorkoutStore.fetchAll()` |
| Rest timer              | Add a `TimerView` sheet in `NewWorkoutView` |
| Export to CSV           | Add a share button in `WorkoutDetailView` |
| Push notifications      | `UNUserNotificationCenter` in `FitLogApp` |

---

## License
MIT — free to use and modify.
