import CoreData
import Foundation

// ─────────────────────────────────────────────────────
// MARK: - WorkoutRecord
// ─────────────────────────────────────────────────────
@objc(WorkoutRecord)
public class WorkoutRecord: NSManagedObject {}

extension WorkoutRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutRecord> {
        NSFetchRequest<WorkoutRecord>(entityName: "WorkoutRecord")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var date: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var exercises: NSSet?

    // Convenience
    var wrappedName: String { name ?? "Workout" }
    var wrappedDate: Date   { date ?? Date() }

    var exercisesArray: [ExerciseRecord] {
        (exercises as? Set<ExerciseRecord> ?? []).sorted { $0.order < $1.order }
    }

    var totalSets: Int {
        exercisesArray.reduce(0) { $0 + $1.setsArray.count }
    }

    /// 0 = Monday … 6 = Sunday
    var weekdayIndex: Int {
        (Calendar.current.component(.weekday, from: wrappedDate) + 5) % 7
    }
}
extension WorkoutRecord: Identifiable {}

// ─────────────────────────────────────────────────────
// MARK: - ExerciseRecord
// ─────────────────────────────────────────────────────
@objc(ExerciseRecord)
public class ExerciseRecord: NSManagedObject {}

extension ExerciseRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseRecord> {
        NSFetchRequest<ExerciseRecord>(entityName: "ExerciseRecord")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var order: Int16
    @NSManaged public var workout: WorkoutRecord?
    @NSManaged public var sets: NSSet?

    var wrappedName: String { name ?? "Exercise" }

    var setsArray: [SetRecord] {
        (sets as? Set<SetRecord> ?? []).sorted { $0.order < $1.order }
    }
}
extension ExerciseRecord: Identifiable {}

// ─────────────────────────────────────────────────────
// MARK: - SetRecord
// ─────────────────────────────────────────────────────
@objc(SetRecord)
public class SetRecord: NSManagedObject {}

extension SetRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SetRecord> {
        NSFetchRequest<SetRecord>(entityName: "SetRecord")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var reps: Int16
    @NSManaged public var weight: Double
    @NSManaged public var order: Int16
    @NSManaged public var exercise: ExerciseRecord?
}
extension SetRecord: Identifiable {}
