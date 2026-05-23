import CoreData
import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutRecord

    private let dateFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f
    }()

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerSection
                    exercisesSection
                    Spacer(minLength: 40)
                }
                .padding(16)
            }
        }
        .navigationTitle(workout.wrappedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBG, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateFmt.string(from: workout.wrappedDate))
                .font(.system(size: 14))
                .foregroundColor(.textSec)

            HStack(spacing: 12) {
                StatPill(value: "\(workout.exercisesArray.count)", label: "Exercises")
                StatPill(value: "\(workout.totalSets)", label: "Sets")
                StatPill(value: totalVolume, label: "Volume")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }

    private var totalVolume: String {
        let vol = workout.exercisesArray.reduce(0.0) { total, ex in
            total + ex.setsArray.reduce(0.0) { $0 + Double($1.reps) * $1.weight }
        }
        if vol == 0 { return "—" }
        return vol >= 1000 ? String(format: "%.1fk", vol / 1000) : vol.neatString
    }

    // MARK: - Exercises

    private var exercisesSection: some View {
        ForEach(groupedExercises, id: \.group) { section in
            VStack(alignment: .leading, spacing: 8) {
                if !section.group.isEmpty {
                    Text(section.group.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.brandAmber)
                        .padding(.top, 4)
                }

                ForEach(section.exercises) { exercise in
                    ExerciseDetailCard(exercise: exercise)
                }
            }
        }
    }

    private var groupedExercises: [ExerciseGroup] {
        var groups: [ExerciseGroup] = []
        for ex in workout.exercisesArray {
            let g = ex.wrappedGroup
            if let last = groups.last, last.group == g {
                groups[groups.count - 1].exercises.append(ex)
            } else {
                groups.append(ExerciseGroup(group: g, exercises: [ex]))
            }
        }
        return groups
    }
}

private struct ExerciseGroup: Identifiable {
    let group: String
    var exercises: [ExerciseRecord]
    var id: String { group + exercises.map { $0.wrappedName }.joined() }
}

// MARK: - Exercise Detail Card

private struct ExerciseDetailCard: View {
    let exercise: ExerciseRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.wrappedName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPri)

            HStack(spacing: 8) {
                Text("SET")
                    .frame(width: 36)
                Text("REPS")
                    .frame(maxWidth: .infinity)
                Text("WEIGHT")
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.textTer)
            .tracking(0.5)

            ForEach(Array(exercise.setsArray.enumerated()), id: \.element.id) { index, set in
                SetDetailRow(index: index + 1, set: set)
            }
        }
        .padding(14)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }
}

// MARK: - Set Detail Row

private struct SetDetailRow: View {
    let index: Int
    let set: SetRecord

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.textTer)
                .frame(width: 36)

            Text("\(set.reps)")
                .font(.system(size: 15))
                .foregroundColor(.textPri)
                .frame(maxWidth: .infinity)

            Text(set.weight > 0 ? set.weight.neatString : "—")
                .font(.system(size: 15))
                .foregroundColor(.textPri)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPri)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textTer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.surface2)
        .cornerRadius(.rSM)
    }
}
