import CoreData
import SwiftUI

struct ReviewWorkoutView: View {
    let image: UIImage
    let onSave: () -> Void

    @Environment(\.managedObjectContext) private var ctx

    @State private var workoutName = "Workout"
    @State private var workoutDate = Date()
    @State private var exercises: [DraftExercise] = []
    @State private var isAnalyzing = true

    var body: some View {
        ZStack {
            Color.appBG.ignoresSafeArea()

            if isAnalyzing {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.brand)
                    Text("Analyzing image…")
                        .font(.system(size: 14))
                        .foregroundColor(.textTer)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        workoutInfoSection
                        exercisesList
                        addExerciseButton
                        Spacer(minLength: 80)
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Review Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBG, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveWorkout() }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.brand)
                    .disabled(isAnalyzing)
            }
        }
        .task {
            let result = await WorkoutImageAnalyzer.analyze(image: image)
            workoutName = result.workoutName
            exercises = result.exercises
            isAnalyzing = false
        }
    }

    // MARK: - Sections

    private var workoutInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WORKOUT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textTer)
                .tracking(0.8)

            TextField("Workout Name", text: $workoutName)
                .font(.system(size: 16))
                .foregroundColor(.textPri)
                .padding(12)
                .background(Color.surface2)
                .cornerRadius(.rSM)

            DatePicker("Date", selection: $workoutDate, displayedComponents: .date)
                .font(.system(size: 16))
                .foregroundColor(.textPri)
                .tint(.brand)
                .padding(12)
                .background(Color.surface2)
                .cornerRadius(.rSM)
        }
        .padding(14)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }

    private var exercisesList: some View {
        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
            if shouldShowGroupHeader(at: index) {
                Text(exercise.group.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.brandAmber)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, index == 0 ? 0 : 4)
            }

            ExerciseEditCard(exercise: $exercises[index]) {
                exercises.removeAll { $0.id == exercise.id }
            }
        }
    }

    private func shouldShowGroupHeader(at index: Int) -> Bool {
        let group = exercises[index].group
        guard !group.isEmpty else { return false }
        if index == 0 { return true }
        return exercises[index - 1].group != group
    }

    private var addExerciseButton: some View {
        Button {
            exercises.append(DraftExercise())
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.brand)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(Color.surface1)
            .cornerRadius(.rMD)
        }
    }

    // MARK: - Save

    private func saveWorkout() {
        let workout = WorkoutRecord(context: ctx)
        workout.id = UUID()
        workout.name = workoutName
        workout.date = workoutDate
        workout.createdAt = Date()

        for (i, exercise) in exercises.enumerated() {
            guard !exercise.name.isEmpty else { continue }
            let ex = ExerciseRecord(context: ctx)
            ex.id = UUID()
            ex.name = exercise.name
            ex.group = exercise.group.isEmpty ? nil : exercise.group
            ex.order = Int16(i)
            ex.workout = workout

            for (j, set) in exercise.sets.enumerated() {
                let s = SetRecord(context: ctx)
                s.id = UUID()
                s.reps = Int16(set.reps)
                s.weight = set.weight
                s.order = Int16(j)
                s.exercise = ex
            }
        }

        try? ctx.save()
        onSave()
    }
}

// MARK: - Exercise Edit Card

private struct ExerciseEditCard: View {
    @Binding var exercise: DraftExercise
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("EXERCISE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textTer)
                    .tracking(0.8)
                Spacer()
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.brand)
                }
            }

            TextField("Exercise Name", text: $exercise.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.textPri)
                .padding(12)
                .background(Color.surface2)
                .cornerRadius(.rSM)

            HStack(spacing: 8) {
                Text("SET")
                    .frame(width: 36)
                Text("REPS")
                    .frame(maxWidth: .infinity)
                Text("WEIGHT")
                    .frame(maxWidth: .infinity)
                Spacer().frame(width: 34)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.textTer)
            .tracking(0.5)

            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, _ in
                SetEditRow(
                    index: index + 1,
                    set: $exercise.sets[index],
                    canDelete: exercise.sets.count > 1,
                    onDelete: {
                        withAnimation { _ = exercise.sets.remove(at: index) }
                    }
                )
            }

            Button {
                let last = exercise.sets.last
                exercise.sets.append(DraftSet(reps: last?.reps ?? 10, weight: last?.weight ?? 0))
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.brand)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }
}

// MARK: - Set Edit Row

private struct SetEditRow: View {
    let index: Int
    @Binding var set: DraftSet
    var canDelete: Bool = false
    var onDelete: (() -> Void)?

    @State private var swipeOffset: CGFloat = 0
    @State private var showDeleteAction = false

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteBackground
            rowContent
        }
        .clipped()
    }

    @ViewBuilder
    private var deleteBackground: some View {
        if showDeleteAction {
            Button {
                onDelete?()
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .frame(maxHeight: .infinity)
            }
            .background(Color.brand)
            .cornerRadius(.rSM)
        }
    }

    private var rowContent: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(set.completed ? .white.opacity(0.7) : .textTer)
                .frame(width: 36)

            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .font(.system(size: 15))
                .foregroundColor(set.completed ? .white : .textPri)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(set.completed ? Color.fitGreen.opacity(0.3) : Color.surface2)
                .cornerRadius(.rSM)

            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .font(.system(size: 15))
                .foregroundColor(set.completed ? .white : .textPri)
                .multilineTextAlignment(.center)
                .padding(8)
                .background(set.completed ? Color.fitGreen.opacity(0.3) : Color.surface2)
                .cornerRadius(.rSM)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    set.completed.toggle()
                }
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(set.completed ? .fitGreen : .surface3)
            }
            .frame(width: 34)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: .rSM)
                .fill(set.completed ? Color.fitGreen.opacity(0.12) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.2), value: set.completed)
        .offset(x: swipeOffset)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard canDelete else { return }
                    if value.translation.width < 0 {
                        swipeOffset = value.translation.width
                        showDeleteAction = value.translation.width < -70
                    }
                }
                .onEnded { _ in
                    guard canDelete else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        if swipeOffset < -70 {
                            swipeOffset = -70
                            showDeleteAction = true
                        } else {
                            swipeOffset = 0
                            showDeleteAction = false
                        }
                    }
                }
        )
    }
}

