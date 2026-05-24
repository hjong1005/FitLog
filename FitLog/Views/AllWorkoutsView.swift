import CoreData
import SwiftUI

struct AllWorkoutsView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutRecord.date, ascending: false)],
        animation: .default
    )
    private var workouts: FetchedResults<WorkoutRecord>

    @State private var selectedWorkout: WorkoutRecord?

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            if workouts.isEmpty {
                VStack(spacing: 12) {
                    Text("No workouts yet")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPri)
                    Text("Your logged workouts will appear here")
                        .font(.system(size: 14))
                        .foregroundColor(.textTer)
                }
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(groupedByMonth, id: \.month) { section in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section.month)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.textTer)
                                    .tracking(0.5)
                                    .padding(.top, 8)

                                ForEach(section.workouts) { w in
                                    SwipeToDeleteCard(
                                        onDelete: { deleteWorkout(w) },
                                        onTap: { selectedWorkout = w }
                                    ) {
                                        WorkoutCard(workout: w)
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("All Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBG, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }

    private func deleteWorkout(_ workout: WorkoutRecord) {
        ctx.delete(workout)
        try? ctx.save()
    }

    private var groupedByMonth: [MonthSection] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"

        var sections: [MonthSection] = []
        for w in workouts {
            let month = fmt.string(from: w.wrappedDate)
            if let last = sections.last, last.month == month {
                sections[sections.count - 1].workouts.append(w)
            } else {
                sections.append(MonthSection(month: month, workouts: [w]))
            }
        }
        return sections
    }
}

private struct MonthSection {
    let month: String
    var workouts: [WorkoutRecord]
}
