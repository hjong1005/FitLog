import Combine
import CoreData
import Foundation

final class WorkoutStore: ObservableObject {
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Fetch
    func fetchAll() -> [WorkoutRecord] {
        let req = WorkoutRecord.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutRecord.date, ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    // MARK: - Stats

    /// Number of workouts in the current Mon–Sun week
    func workoutsThisWeek(from all: [WorkoutRecord]) -> Int {
        guard let monday = mondayOfCurrentWeek() else { return 0 }
        let sunday = Calendar.current.date(byAdding: .day, value: 6, to: monday)!
        let end    = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: sunday)!
        return all.filter { $0.wrappedDate >= monday && $0.wrappedDate <= end }.count
    }

    /// Number of workouts in the previous calendar month
    func workoutsLastMonth(from all: [WorkoutRecord]) -> Int {
        let cal = Calendar.current
        let now = Date()
        guard
            let startOfLastMonth = cal.date(from: cal.dateComponents(
                [.year, .month],
                from: cal.date(byAdding: .month, value: -1, to: now)!
            )),
            let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))
        else { return 0 }
        let endOfLastMonth = cal.date(byAdding: .second, value: -1, to: startOfThisMonth)!
        return all.filter {
            $0.wrappedDate >= startOfLastMonth && $0.wrappedDate <= endOfLastMonth
        }.count
    }

    /// Consecutive Mon–Sun weeks (going back) that contain ≥ 1 workout
    func weeklyStreak(from all: [WorkoutRecord]) -> Int {
        let cal   = Calendar.current
        let dates = Set(all.map { cal.startOfDay(for: $0.wrappedDate) })
        guard var monday = mondayOfCurrentWeek() else { return 0 }
        var streak = 0

        for _ in 0..<52 {
            let sunday = cal.date(byAdding: .day, value: 6, to: monday)!
            let hasWork = dates.contains { $0 >= monday && $0 <= sunday }
            guard hasWork else { break }
            streak += 1
            monday = cal.date(byAdding: .day, value: -7, to: monday)!
        }
        return streak
    }

    /// The most-recently-logged workout (for "last trained" display)
    func lastWorkout(from all: [WorkoutRecord]) -> WorkoutRecord? {
        all.sorted { $0.wrappedDate > $1.wrappedDate }.first
    }

    // MARK: - Helpers
    func mondayOfCurrentWeek() -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        // Days since Monday: Sun=6, Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5
        let daysSinceMonday = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysSinceMonday, to: today)
    }

    func weekRangeString() -> String {
        guard let monday = mondayOfCurrentWeek() else { return "" }
        let sunday = Calendar.current.date(byAdding: .day, value: 6, to: monday)!
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return "\(fmt.string(from: monday)) – \(fmt.string(from: sunday))"
    }

    // MARK: - Delete
    func delete(_ workout: WorkoutRecord) {
        context.delete(workout)
        try? context.save()
    }
}

// MARK: - Draft models (used by NewWorkoutView, included for future use)
struct DraftExercise: Identifiable {
    var id       = UUID()
    var name     = ""
    var group    = ""
    var hasGroup = false
    var sets: [DraftSet] = [DraftSet()]
}

struct DraftSet: Identifiable {
    var id        = UUID()
    var reps      = 10
    var weight    = 0.0
    var completed = false
}
