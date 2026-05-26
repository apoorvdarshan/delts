import Foundation
import SwiftData

struct CompletedSetLog: Codable, Identifiable, Hashable {
    var id: UUID
    var setNumber: Int
    var completed: Bool
    var weight: String
    var reps: String

    init(id: UUID = UUID(), setNumber: Int, completed: Bool, weight: String, reps: String) {
        self.id = id
        self.setNumber = setNumber
        self.completed = completed
        self.weight = weight
        self.reps = reps
    }
}

struct CompletedExerciseLog: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var targetMuscle: String
    var equipment: String
    var sets: [CompletedSetLog]

    init(id: UUID = UUID(), name: String, targetMuscle: String, equipment: String, sets: [CompletedSetLog]) {
        self.id = id
        self.name = name
        self.targetMuscle = targetMuscle
        self.equipment = equipment
        self.sets = sets
    }
}

@Model
final class CompletedWorkout: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var date: Date
    var durationMinutes: Int
    var planSummary: String
    var exercisesData: String

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        durationMinutes: Int,
        planSummary: String,
        exerciseLogs: [CompletedExerciseLog]
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.durationMinutes = durationMinutes
        self.planSummary = planSummary
        self.exercisesData = Self.encode(exerciseLogs)
    }

    var exerciseLogs: [CompletedExerciseLog] {
        guard let data = exercisesData.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([CompletedExerciseLog].self, from: data)) ?? []
    }

    func replaceExerciseLogs(_ logs: [CompletedExerciseLog]) {
        exercisesData = Self.encode(logs)
    }

    private static func encode(_ logs: [CompletedExerciseLog]) -> String {
        guard let data = try? JSONEncoder().encode(logs) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

