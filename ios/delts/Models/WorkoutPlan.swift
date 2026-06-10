import Foundation
import SwiftData

@Model
final class WorkoutExercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var name: String
    var targetMuscleRaw: String
    var equipmentRaw: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var formTip: String
    var difficulty: String

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        name: String,
        targetMuscle: MuscleGroup,
        equipment: Equipment,
        sets: Int,
        reps: String,
        restSeconds: Int,
        formTip: String,
        difficulty: String
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.name = name
        self.targetMuscleRaw = targetMuscle.rawValue
        self.equipmentRaw = equipment.rawValue
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.formTip = formTip
        self.difficulty = difficulty
    }

    var targetMuscle: MuscleGroup {
        MuscleGroup(rawValue: targetMuscleRaw) ?? .fullBody
    }

    var equipment: Equipment {
        Equipment(rawValue: equipmentRaw) ?? .bodyweight
    }

    var restDisplay: String {
        if restSeconds >= 60 {
            return String(localized: "\(restSeconds / 60)m")
        }
        return String(localized: "\(restSeconds)s")
    }
}

@Model
final class WorkoutPlan: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    var muscleGroupRaw: String
    var goalRaw: String
    var durationMinutes: Int
    var generatedByAI: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        muscleGroup: MuscleGroup,
        goal: FitnessGoal,
        durationMinutes: Int,
        generatedByAI: Bool = false,
        createdAt: Date = Date(),
        exercises: [WorkoutExercise]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.muscleGroupRaw = muscleGroup.rawValue
        self.goalRaw = goal.rawValue
        self.durationMinutes = durationMinutes
        self.generatedByAI = generatedByAI
        self.createdAt = createdAt
        self.exercises = exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var muscleGroup: MuscleGroup {
        MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody
    }

    var goal: FitnessGoal {
        FitnessGoal(rawValue: goalRaw) ?? .muscleGain
    }
}

