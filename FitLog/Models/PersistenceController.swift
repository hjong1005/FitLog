import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // MARK: - Stack
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FitLog")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production replace with proper error handling / user alert
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Preview helper with rich sample data
    static var preview: PersistenceController = {
        let c = PersistenceController(inMemory: true)
        let ctx = c.container.viewContext

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let samples: [(String, String, [(String, [(Int, Double)])])] = [
            ("Push Day", "2025-04-25", [
                ("Bench Press",    [(10,60),(8,65),(6,70)]),
                ("Overhead Press", [(12,40),(10,42.5),(8,45)]),
                ("Tricep Dips",    [(15,0),(12,0)]),
                ("Cable Flyes",    [(12,15),(10,17.5)])
            ]),
            ("Pull Day", "2025-04-23", [
                ("Deadlift",    [(5,120),(5,125),(3,130)]),
                ("Barbell Row", [(10,70),(8,75)]),
                ("Pull-ups",    [(10,0),(8,0),(7,0)]),
                ("Bicep Curls", [(12,15),(10,17.5)]),
                ("Face Pulls",  [(15,12),(15,12)])
            ]),
            ("Leg Day", "2025-04-21", [
                ("Squat",          [(8,100),(8,100),(6,105)]),
                ("Romanian DL",    [(10,80),(10,80)]),
                ("Leg Press",      [(12,140),(10,150)]),
                ("Calf Raises",    [(20,40),(18,40),(15,45)])
            ]),
            ("Upper Body", "2025-04-17", [
                ("Bench Press",    [(10,60),(8,65)]),
                ("Barbell Row",    [(10,70),(8,72.5)]),
                ("Shoulder Press", [(12,40),(10,42.5)]),
                ("Pull-ups",       [(8,0),(7,0)])
            ]),
            ("Leg Day", "2025-04-14", [
                ("Squat",        [(8,95),(8,100)]),
                ("Romanian DL",  [(10,75),(10,80)]),
                ("Leg Press",    [(12,130),(12,140)]),
                ("Calf Raises",  [(20,40),(18,40)])
            ]),
            // Last month (March)
            ("Push Day",   "2025-03-31", [("Bench Press",[(10,57.5),(8,60)]),("OHP",[(12,37.5),(10,40)])]),
            ("Pull Day",   "2025-03-28", [("Deadlift",[(5,110),(5,115)]),("Row",[(10,65),(8,70)])]),
            ("Leg Day",    "2025-03-24", [("Squat",[(8,90),(8,92.5)]),("RDL",[(10,72.5),(10,75)])]),
            ("Upper Body", "2025-03-17", [("Bench",[(10,55),(8,57.5)]),("Row",[(10,62.5),(8,65)])]),
            ("Push Day",   "2025-03-10", [("Bench",[(10,55),(8,57.5)]),("OHP",[(12,35),(10,37.5)])]),
            ("Leg Day",    "2025-03-03", [("Squat",[(8,87.5),(8,90)]),("RDL",[(10,70),(10,72.5)])]),
            ("Full Body",  "2025-03-01", [("Squat",[(8,85),(8,87.5)]),("Bench",[(8,55),(8,57.5)]),("DL",[(5,100),(5,105)])]),
            ("Pull Day",   "2025-03-07", [("DL",[(5,107.5),(5,110)]),("Row",[(10,62.5),(8,65)])]),
        ]

        for (name, dateStr, exercises) in samples {
            let w = WorkoutRecord(context: ctx)
            w.id        = UUID()
            w.name      = name
            w.date      = fmt.date(from: dateStr) ?? Date()
            w.createdAt = Date()

            for (i, (exName, sets)) in exercises.enumerated() {
                let ex = ExerciseRecord(context: ctx)
                ex.id      = UUID()
                ex.name    = exName
                ex.order   = Int16(i)
                ex.workout = w

                for (j, (reps, weight)) in sets.enumerated() {
                    let s = SetRecord(context: ctx)
                    s.id       = UUID()
                    s.reps     = Int16(reps)
                    s.weight   = weight
                    s.order    = Int16(j)
                    s.exercise = ex
                }
            }
        }
        try? ctx.save()
        return c
    }()
}
