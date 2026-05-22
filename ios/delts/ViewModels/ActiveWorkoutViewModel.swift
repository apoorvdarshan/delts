import Combine
import SwiftUI

@MainActor
final class ActiveWorkoutViewModel: ObservableObject {
    let plan: WorkoutPlan
    @Published var currentExerciseIndex: Int
    @Published var completedSets: [[Bool]]
    @Published var weightInputs: [[String]]
    @Published var repInputs: [[String]]

    init(plan: WorkoutPlan, startIndex: Int = 0) {
        self.plan = plan
        let sortedExercises = plan.exercises.sorted { $0.orderIndex < $1.orderIndex }
        self.currentExerciseIndex = min(max(startIndex, 0), max(sortedExercises.count - 1, 0))
        self.completedSets = sortedExercises.map { Array(repeating: false, count: max($0.sets, 1)) }
        self.weightInputs = sortedExercises.map { Array(repeating: "", count: max($0.sets, 1)) }
        self.repInputs = sortedExercises.map { exercise in
            Array(repeating: exercise.reps.components(separatedBy: "-").last ?? exercise.reps, count: max(exercise.sets, 1))
        }
    }

    var exercises: [WorkoutExercise] {
        plan.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var currentExercise: WorkoutExercise? {
        guard exercises.indices.contains(currentExerciseIndex) else { return nil }
        return exercises[currentExerciseIndex]
    }

    var isLastExercise: Bool {
        currentExerciseIndex >= exercises.count - 1
    }

    var progressText: String {
        guard !exercises.isEmpty else { return "0 / 0" }
        return "\(currentExerciseIndex + 1) / \(exercises.count)"
    }

    func toggleSet(_ setIndex: Int) {
        guard completedSets.indices.contains(currentExerciseIndex),
              completedSets[currentExerciseIndex].indices.contains(setIndex)
        else { return }

        completedSets[currentExerciseIndex][setIndex].toggle()
    }

    func nextExercise() {
        guard !isLastExercise else { return }
        currentExerciseIndex += 1
    }

    func makeCompletedWorkout() -> CompletedWorkout {
        let logs = exercises.enumerated().map { exerciseIndex, exercise in
            let sets = (0..<max(exercise.sets, 1)).map { setIndex in
                CompletedSetLog(
                    setNumber: setIndex + 1,
                    completed: completedSets[safe: exerciseIndex]?[safe: setIndex] ?? false,
                    weight: weightInputs[safe: exerciseIndex]?[safe: setIndex] ?? "",
                    reps: repInputs[safe: exerciseIndex]?[safe: setIndex] ?? ""
                )
            }

            return CompletedExerciseLog(
                name: exercise.name,
                targetMuscle: exercise.targetMuscle.title,
                equipment: exercise.equipment.title,
                sets: sets
            )
        }

        return CompletedWorkout(
            title: plan.title,
            durationMinutes: plan.durationMinutes,
            planSummary: plan.summary,
            exerciseLogs: logs
        )
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
