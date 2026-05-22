import SwiftData
import SwiftUI

struct WorkoutsView: View {
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var workouts: [CompletedWorkout]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if workouts.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(workouts) { workout in
                                NavigationLink {
                                    CompletedWorkoutDetailView(workout: workout)
                                } label: {
                                    workoutRow(workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .deltsScreen()
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Workout history")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text("Completed sessions save locally with set, weight, and rep inputs.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 14) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Color.deltsElectricBlue)
                Text("No completed workouts yet")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Generate a plan, start it, then finish to create your first log.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.62))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func workoutRow(_ workout: CompletedWorkout) -> some View {
        GlassCard(padding: 14) {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.deltsElectricBlue)
                    .frame(width: 44, height: 44)
                    .background(Color.deltsElectricBlue.opacity(0.13), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                    Text("\(workout.exerciseLogs.count) exercises - \(workout.durationMinutes)m")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}

struct CompletedWorkoutDetailView: View {
    let workout: CompletedWorkout

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(workout.title)
                            .font(.largeTitle.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.72)
                        Text(workout.date.formatted(date: .complete, time: .shortened))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.deltsElectricBlue)
                        Text(workout.planSummary)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ForEach(workout.exerciseLogs) { exercise in
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.white)
                                    Text("\(exercise.targetMuscle) - \(exercise.equipment)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.58))
                                }
                                Spacer()
                                Text("\(exercise.sets.filter(\.completed).count)/\(exercise.sets.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 10)
                                    .background(Color.deltsElectricBlue.opacity(0.18), in: Capsule())
                            }

                            ForEach(exercise.sets) { set in
                                HStack {
                                    Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(set.completed ? Color.deltsElectricBlue : Color.white.opacity(0.35))
                                    Text("Set \(set.setNumber)")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(weightRepText(for: set))
                                        .foregroundStyle(.white.opacity(0.66))
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .deltsScreen()
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func weightRepText(for set: CompletedSetLog) -> String {
        let weight = set.weight.isEmpty ? "--" : set.weight
        let reps = set.reps.isEmpty ? "--" : set.reps
        return "\(weight) x \(reps)"
    }
}

