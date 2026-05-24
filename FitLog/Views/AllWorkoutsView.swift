import CoreData
import SwiftUI

struct AllWorkoutsView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutRecord.date, ascending: false)],
        animation: .default
    )
    private var workouts: FetchedResults<WorkoutRecord>

    @State private var selectedDay: Int?
    @State private var selectedWorkout: WorkoutRecord?

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    // Calendar weekday values: Mon=2, Tue=3, Wed=4, Thu=5, Fri=6, Sat=7, Sun=1
    private let calendarWeekdays = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            VStack(spacing: 0) {
                dayFilterBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if let day = selectedDay {
                    filterSubtitle(for: day)
                        .padding(.top, 6)
                }

                if workouts.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text("No workouts yet")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.textPri)
                        Text("Your logged workouts will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.textTer)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            if selectedDay == nil {
                                weeklyView
                            } else {
                                dayFilterView
                            }
                            Spacer(minLength: 40)
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appBG, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }

    // MARK: - Day Filter Bar

    private var dayFilterBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDay = selectedDay == index ? nil : index
                    }
                } label: {
                    Text(dayLabels[index])
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(selectedDay == index ? .white : .textSec)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(selectedDay == index ? Color.brand : Color.clear)
                        )
                        .overlay(
                            Circle()
                                .stroke(selectedDay == index ? Color.clear : Color.surface3, lineWidth: 1.5)
                        )
                }
            }
        }
    }

    private func filterSubtitle(for day: Int) -> some View {
        let dayNames = ["Mondays", "Tuesdays", "Wednesdays", "Thursdays", "Fridays", "Saturdays", "Sundays"]
        return Text("All \(dayNames[day])")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.textTer)
    }

    // MARK: - Weekly View

    private var weeklyView: some View {
        ForEach(groupedByWeek, id: \.id) { section in
            VStack(alignment: .leading, spacing: 8) {
                weekSectionHeader(section: section)

                ForEach(section.workouts) { w in
                    SwipeToDeleteCard(
                        onDelete: { deleteWorkout(w) },
                        onTap: { selectedWorkout = w }
                    ) {
                        WeeklyWorkoutRow(workout: w)
                    }
                }
            }
        }
    }

    private func weekSectionHeader(section: WeekSection) -> some View {
        HStack {
            if section.isCurrentWeek {
                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.brandAmber)
                    .tracking(0.8)
            }
            Text(section.dateRange)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(section.isCurrentWeek ? .textPri : .textSec)
            Spacer()
            Pill(text: "\(section.workouts.count) workouts", color: section.isCurrentWeek ? .brand : .textTer)
        }
        .padding(.top, 4)
    }

    private func mondayOf(_ date: Date) -> Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        let weekday = cal.component(.weekday, from: day)
        let daysSinceMonday = (weekday + 5) % 7
        return cal.date(byAdding: .day, value: -daysSinceMonday, to: day)!
    }

    private var groupedByWeek: [WeekSection] {
        let cal = Calendar.current
        var sections: [WeekSection] = []
        let currentMonday = mondayOf(Date())

        for w in workouts {
            let monday = mondayOf(w.wrappedDate)
            if let last = sections.last, last.weekStart == monday {
                sections[sections.count - 1].workouts.append(w)
            } else {
                let isCurrentWeek = monday == currentMonday
                let sunday = cal.date(byAdding: .day, value: 6, to: monday)!
                let range = formatDateRange(start: monday, end: sunday)
                sections.append(WeekSection(
                    weekStart: monday,
                    dateRange: range,
                    isCurrentWeek: isCurrentWeek,
                    workouts: [w]
                ))
            }
        }
        return sections
    }

    private func formatDateRange(start: Date, end: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        return "\(fmt.string(from: start)) – \(fmt.string(from: end))"
    }

    // MARK: - Day Filter View

    private var dayFilterView: some View {
        let filtered = filteredByDay
        if filtered.isEmpty {
            return AnyView(
                VStack(spacing: 12) {
                    Text("No workouts")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPri)
                    Text("No workouts recorded on this day")
                        .font(.system(size: 14))
                        .foregroundColor(.textTer)
                }
                .padding(.top, 40)
            )
        }

        return AnyView(
            ForEach(filtered, id: \.month) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.month)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPri)
                        .padding(.top, 4)

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
        )
    }

    private var filteredByDay: [MonthSection] {
        guard let day = selectedDay else { return [] }
        let weekday = calendarWeekdays[day]
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"

        let filtered = workouts.filter { cal.component(.weekday, from: $0.wrappedDate) == weekday }

        var sections: [MonthSection] = []
        for w in filtered {
            let month = fmt.string(from: w.wrappedDate)
            if let last = sections.last, last.month == month {
                sections[sections.count - 1].workouts.append(w)
            } else {
                sections.append(MonthSection(month: month, workouts: [w]))
            }
        }
        return sections
    }

    // MARK: - Delete

    private func deleteWorkout(_ workout: WorkoutRecord) {
        ctx.delete(workout)
        try? ctx.save()
    }
}

// MARK: - Weekly Workout Row

private struct WeeklyWorkoutRow: View {
    let workout: WorkoutRecord

    private var dayAbbrev: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: workout.wrappedDate)
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.brand)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(workout.wrappedName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
                Text("\(workout.exercisesArray.count) exercises · \(workout.totalSets) sets")
                    .font(.system(size: 12))
                    .foregroundColor(.textTer)
            }

            Spacer()

            Text(dayAbbrev)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.textTer)
        }
        .padding(12)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }
}

// MARK: - Supporting Types

private struct WeekSection: Identifiable {
    let weekStart: Date
    let dateRange: String
    let isCurrentWeek: Bool
    var workouts: [WorkoutRecord]
    var id: Date { weekStart }
}

private struct MonthSection {
    let month: String
    var workouts: [WorkoutRecord]
}
