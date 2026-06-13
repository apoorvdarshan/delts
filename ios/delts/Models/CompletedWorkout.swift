import Foundation
import SwiftData

struct CompletedSetLog: Codable, Identifiable, Hashable {
    var id: UUID
    var setNumber: Int
    var completed: Bool
    var weight: String
    /// Unit the weight was logged in ("kg" or "lb"); nil for older logs or no weight.
    var weightUnit: String?
    var reps: String
    var rpe: String?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        completed: Bool,
        weight: String,
        weightUnit: String? = nil,
        reps: String,
        rpe: String? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.completed = completed
        self.weight = weight
        self.weightUnit = weightUnit
        self.reps = reps
        self.rpe = rpe
    }

    /// "82.5 kg" style display, or empty if no weight logged.
    var weightDisplay: String {
        let trimmed = weight.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        return weightUnit.map { "\(trimmed) \($0)" } ?? trimmed
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
    var caloriesBurned: Int?
    var exercisesData: String

    init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        durationMinutes: Int,
        planSummary: String,
        caloriesBurned: Int? = nil,
        exerciseLogs: [CompletedExerciseLog]
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.durationMinutes = durationMinutes
        self.planSummary = planSummary
        self.caloriesBurned = caloriesBurned
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
