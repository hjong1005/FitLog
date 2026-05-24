import CoreData
import SwiftUI

// ═══════════════════════════════════════════════════════════
// MARK: - HomeView
// ═══════════════════════════════════════════════════════════
struct HomeView: View {
    @Environment(\.managedObjectContext) private var ctx

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutRecord.date, ascending: false)],
        animation: .default
    )
    private var workouts: FetchedResults<WorkoutRecord>

    /// Lazy-init store so it picks up the injected context
    @StateObject private var store: WorkoutStore

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _store = StateObject(wrappedValue: WorkoutStore(context: ctx))
    }

    // Sheet state – ready for when NewWorkoutView is added
    @State private var showNewWorkout = false

    private var all: [WorkoutRecord] { Array(workouts) }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // ── 1. Hero lifetime card
                        HeroCard(count: all.count,
                                 label: "LIFETIME",
                                 subtitle: "total workouts")
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // ── 2. Stat tiles
                        HStack(spacing: 10) {
                            StatTile(
                                value: "\(store.workoutsLastMonth(from: all))",
                                label: "Last Month"
                            )
                            StatTile(
                                value: "\(store.workoutsThisWeek(from: all))",
                                label: store.weekRangeString()
                            )
                            StatTile(
                                value: "\(store.weeklyStreak(from: all)) 🔥",
                                label: "Weekly Streak"
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // ── 3. Recent workouts
                        RecentSection(workouts: Array(all.prefix(3))) { workout in
                            ctx.delete(workout)
                            try? ctx.save()
                        }
                            .padding(.horizontal, 16)
                            .padding(.top, 20)

                        Spacer(minLength: 100)
                    }
                }
                .background(Color.appBG.ignoresSafeArea())

                // ── FAB (wired to sheet; NewWorkoutView stub included)
                Button { showNewWorkout = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.brand)
                        .clipShape(Circle())
                        .shadow(color: .brand.opacity(0.5), radius: 14, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("FitLog")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBG, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showNewWorkout) {
                NewWorkoutView()
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - HeroCard
// ═══════════════════════════════════════════════════════════
struct HeroCard: View {
    let count: Int
    var label: String = "THIS WEEK"
    var subtitle: String = "workouts"

    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [.brand, .brandAmber],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(.rLG)

            RoundedRectangle(cornerRadius: .rLG)
                .fill(.white.opacity(0.04))

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .opacity(0.85)

                Text("\(count)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .tracking(-3)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 13))
                    .opacity(0.78)
            }
            .foregroundColor(.white)
            .padding(22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 168)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - LastTrainedBanner
// ═══════════════════════════════════════════════════════════
struct LastTrainedBanner: View {
    let workout: WorkoutRecord

    private var daysAgo: String {
        let days = Calendar.current.dateComponents(
            [.day], from: workout.wrappedDate, to: Date()
        ).day ?? 0
        switch days {
        case 0:  return "today"
        case 1:  return "yesterday"
        default: return "\(days) days ago"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.brandAmber)
                .frame(width: 36, height: 36)
                .background(Color.brandAmber.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Last trained \(daysAgo)")
                    .font(.system(size: 12))
                    .foregroundColor(.textTer)
                Text(workout.wrappedName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPri)
            }
            Spacer()
            Pill(text: "\(workout.exercisesArray.count) ex", color: .brandAmber)
        }
        .padding(14)
        .background(Color.surface1)
        .cornerRadius(.rMD)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - RecentSection
// ═══════════════════════════════════════════════════════════
struct RecentSection: View {
    let workouts: [WorkoutRecord]
    var onDelete: ((WorkoutRecord) -> Void)?

    @State private var selectedWorkout: WorkoutRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Workouts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textPri)
                Spacer()
                NavigationLink(destination: AllWorkoutsView()) {
                    Text("See All")
                        .font(.system(size: 15))
                        .foregroundColor(.brand)
                }
            }

            if workouts.isEmpty {
                EmptyRecentView()
            } else {
                ForEach(workouts) { w in
                    SwipeToDeleteCard(
                        onDelete: { onDelete?(w) },
                        onTap: { selectedWorkout = w }
                    ) {
                        WorkoutCard(workout: w)
                    }
                }
            }
        }
        .navigationDestination(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - EmptyRecentView
// ═══════════════════════════════════════════════════════════
struct EmptyRecentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🏋️")
                .font(.system(size: 52))
            Text("No workouts yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textPri)
            Text("Tap + to log your first session")
                .font(.system(size: 14))
                .foregroundColor(.textTer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Swipe to Delete Card
// ═══════════════════════════════════════════════════════════
struct SwipeToDeleteCard<Content: View>: View {
    let onDelete: () -> Void
    var onTap: (() -> Void)?
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var showDelete = false
    @State private var isHorizontalDrag = false
    private let threshold: CGFloat = -80

    var body: some View {
        ZStack(alignment: .trailing) {
            if showDelete {
                Button {
                    withAnimation { onDelete() }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                        Text("Delete")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(width: 70)
                    .frame(maxHeight: .infinity)
                }
                .background(Color.brand)
                .cornerRadius(.rMD)
            }

            content
                .offset(x: offset)
        }
        .contentShape(Rectangle())
        .clipped()
        .onTapGesture {
            if showDelete {
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = 0
                    showDelete = false
                }
            } else {
                onTap?()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 15)
                .onChanged { value in
                    if !isHorizontalDrag {
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(value.translation.height)
                        if horizontal > vertical * 1.5 {
                            isHorizontalDrag = true
                        } else {
                            return
                        }
                    }
                    if showDelete && value.translation.width > 0 {
                        let newOffset = threshold + value.translation.width
                        offset = min(newOffset, 0)
                        showDelete = offset < threshold / 2
                    } else if value.translation.width < 0 {
                        offset = value.translation.width
                        showDelete = value.translation.width < threshold
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        if offset < threshold {
                            offset = threshold
                            showDelete = true
                        } else {
                            offset = 0
                            showDelete = false
                        }
                    }
                    isHorizontalDrag = false
                }
        )
    }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════════════════════
#Preview {
    HomeView()
        .environment(\.managedObjectContext,
                     PersistenceController.preview.container.viewContext)
}
