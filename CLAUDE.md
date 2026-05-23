# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

Open and run in Xcode — there are no separate build scripts:

```
open FitLog.xcodeproj
```

Build and run with **⌘R** targeting an iPhone simulator (iOS 17+). There are no automated tests; verify changes in the simulator.

## Architecture

MVVM with SwiftUI + Core Data, dark-mode only (`.preferredColorScheme(.dark)` locked in `FitLogApp`).

**Data flow:**
- `PersistenceController.shared` owns the `NSPersistentContainer` and is injected into the SwiftUI environment at the root (`FitLogApp.swift`).
- `WorkoutStore` is an `ObservableObject` that takes an `NSManagedObjectContext` and exposes stat helpers (`workoutsThisWeek`, `weeklyStreak`, etc.). It does not use `@FetchRequest` internally — views that need live updates use `@FetchRequest` directly, then pass the results into `WorkoutStore` methods.
- Views own `@StateObject private var store: WorkoutStore` and initialise it with `PersistenceController.shared.container.viewContext`.

**Core Data entities** (`FitLog.xcdatamodeld`):
- `WorkoutRecord` → has many `ExerciseRecord` (cascade delete)
- `ExerciseRecord` → has many `SetRecord` (cascade delete), ordered by `order: Int16`
- `SetRecord` — leaf node; `reps: Int16`, `weight: Double`, `order: Int16`

All three NSManagedObject subclasses are hand-written in `Models/CoreDataModels.swift` (no Xcode codegen — `codeGenerationType="none"` in the model).

## Design System

All colours, radii, and reusable primitives live in `Utilities/DesignSystem.swift`:
- Colours: `Color.brand` (crimson), `Color.brandAmber`, `Color.fitGreen`, `Color.fitBlue`, and surface/text semantic tokens (`appBG`, `surface1–3`, `textPri/Sec/Ter`).
- Radii: `CGFloat.rSM / rMD / rLG`
- Components: `Pill`, `StatTile`, `WorkoutCard`
- Use these tokens rather than hard-coded values when adding UI.

## Anthropic API Key

`Utilities/AIAnalysisService.swift` contains a hardcoded `private let apiKey` placeholder. Replace it with a real key from https://console.anthropic.com before using the AI image scan feature. Do not commit a live key.

## Preview Support

`PersistenceController.preview` is a static in-memory store pre-seeded with 13 sample workouts. Use it in `#Preview` blocks:

```swift
#Preview {
    SomeView()
        .environment(\.managedObjectContext,
                     PersistenceController.preview.container.viewContext)
}
```
