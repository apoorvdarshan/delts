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
        equipmentFamily.title
    }

    var equipmentFamily: ExerciseEquipmentFamily {
        ExerciseEquipmentFamily(equipment: equipment)
    }

    var visualAssetName: String {
        id
    }

    var searchableText: String {
        [
            name,
            muscleGroup.title,
            equipment.title,
            level.title,
            goal.title,
            machineLabel,
            formTip
        ]
        .joined(separator: " ")
        .lowercased()
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

enum ExerciseEquipmentFamily: String, CaseIterable, Identifiable, Hashable {
    case all = "All"
    case machines = "Machines"
    case freeWeights = "Free Weights"
    case bodyweight = "Bodyweight"

    var id: String { rawValue }
    var title: String { rawValue }

    init(equipment: Equipment) {
        switch equipment {
        case .chestPress, .shoulderPress, .latPulldown, .rowMachine, .legPress, .legExtension, .legCurl, .smithMachine, .cableMachine, .treadmill:
            self = .machines
        case .dumbbells, .barbell, .bench, .pullUpBar:
            self = .freeWeights
        case .bodyweight:
            self = .bodyweight
        }
    }
}

enum ExerciseLibrarySort: String, CaseIterable, Identifiable, Hashable {
    case bodyPart = "Body Part"
    case name = "Name"
    case level = "Level"
    case equipment = "Equipment"
    case goal = "Goal"

    var id: String { rawValue }
    var title: String { rawValue }
}
