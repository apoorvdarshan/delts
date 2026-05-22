import Foundation

struct ExerciseLibraryItem: Identifiable, Hashable {
    let id: String
    let name: String
    let muscleGroup: MuscleGroup
    let equipment: Equipment
    let level: ExperienceLevel
    let goal: FitnessGoal
    let sets: Int
    let reps: String
    let restSeconds: Int
    let formTip: String

    var difficulty: String {
        level.title
    }

    var machineLabel: String {
        switch equipment {
        case .chestPress, .shoulderPress, .latPulldown, .rowMachine, .legPress, .legExtension, .legCurl, .smithMachine, .cableMachine, .treadmill:
            return "Machine"
        case .dumbbells, .barbell, .bench, .pullUpBar:
            return "Free Weight"
        case .bodyweight:
            return "Bodyweight"
        }
    }

    func workoutExercise(orderIndex: Int = 0) -> WorkoutExercise {
        WorkoutExercise(
            orderIndex: orderIndex,
            name: name,
            targetMuscle: muscleGroup,
            equipment: equipment,
            sets: sets,
            reps: reps,
            restSeconds: restSeconds,
            formTip: formTip,
            difficulty: difficulty
        )
    }

    func singleExercisePlan() -> WorkoutPlan {
        WorkoutPlan(
            title: name,
            summary: "\(muscleGroup.title) movement for \(goal.title.lowercased()) using \(equipment.title.lowercased()).",
            muscleGroup: muscleGroup,
            goal: goal,
            durationMinutes: 15,
            generatedByAI: false,
            exercises: [workoutExercise()]
        )
    }
}

