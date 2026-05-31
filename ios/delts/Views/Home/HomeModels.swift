import Foundation

struct WorkoutPickerContext: Identifiable, Hashable {
    static let all = WorkoutPickerContext(title: "All Workouts", muscles: [])

    let title: String
    let muscles: Set<String>

    var id: String { title }

    var systemImage: String {
        let title = title.lowercased()
        if title.contains("push") { return "arrow.up.forward.circle" }
        if title.contains("pull") { return "arrow.down.backward.circle" }
        if title.contains("leg") || title.contains("quad") || title.contains("hamstring") { return "figure.run" }
        if title.contains("core") || title.contains("ab") { return "figure.core.training" }
        if title.contains("chest") { return "figure.strengthtraining.traditional" }
        if title.contains("back") { return "figure.pullup" }
        if title.contains("shoulder") { return "figure.strengthtraining.functional" }
        if title.contains("arm") || title.contains("bicep") || title.contains("tricep") { return "dumbbell.fill" }
        return "square.grid.2x2"
    }
}

struct WorkoutDayPlan: Codable, Identifiable, Hashable {
    var dateKey: String
    var exercises: [PlannedRoutineExercise] = []

    var id: String { dateKey }
}

struct PlannedRoutineExercise: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var itemID: String
    var name: String
    var primaryMuscles: [String]
    var rawEquipment: String
    var rawLevel: String
    var category: String
    var imagePaths: [String]
    var instructions: [String]
    var sets: Int = 1
    var reps: String = ""

    init(item: ExerciseLibraryItem) {
        self.itemID = item.id
        self.name = item.name
        self.primaryMuscles = item.primaryMuscles
        self.rawEquipment = item.rawEquipment
        self.rawLevel = item.rawLevel
        self.category = item.category
        self.imagePaths = item.imagePaths
        self.instructions = item.instructions
    }
}

enum WorkoutDayPlanStore {
    private static let key = "delts.dailyWorkoutPlans.v1"

    static func key(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    static func load() -> [String: WorkoutDayPlan] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let plans = try? JSONDecoder().decode([String: WorkoutDayPlan].self, from: data)
        else {
            return [:]
        }
        return plans
    }

    static func save(_ plans: [String: WorkoutDayPlan]) {
        guard let data = try? JSONEncoder().encode(plans) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

enum HomeWorkoutPlanFactory {
    static func makePlan(
        title: String,
        summary: String,
        bodyPart: String,
        exercises: [PlannedRoutineExercise]
    ) -> WorkoutPlan {
        WorkoutPlan(
            title: title,
            summary: summary,
            muscleGroup: muscleGroup(for: bodyPart),
            goal: .generalFitness,
            durationMinutes: 0,
            generatedByAI: false,
            exercises: exercises.enumerated().map { index, exercise in
                WorkoutExercise(
                    orderIndex: index,
                    name: exercise.name,
                    targetMuscle: muscleGroup(for: exercise.primaryMuscles.first ?? bodyPart),
                    equipment: equipment(for: exercise.rawEquipment),
                    sets: max(exercise.sets, 1),
                    reps: exercise.reps,
                    restSeconds: 0,
                    formTip: exercise.instructions.first ?? "",
                    difficulty: exercise.rawLevel
                )
            }
        )
    }

    private static func muscleGroup(for rawValue: String) -> MuscleGroup {
        let value = rawValue.lowercased()
        if value.contains("chest") { return .chest }
        if value.contains("back") || value.contains("lat") || value.contains("trap") { return .back }
        if value.contains("leg") || value.contains("quad") || value.contains("hamstring") || value.contains("calf") || value.contains("glute") || value.contains("adductor") || value.contains("abductor") { return .legs }
        if value.contains("shoulder") || value.contains("delt") { return .shoulders }
        if value.contains("bicep") || value.contains("tricep") || value.contains("forearm") { return .arms }
        if value.contains("abdominal") || value.contains("core") { return .core }
        return .fullBody
    }

    private static func equipment(for rawValue: String) -> Equipment {
        let value = rawValue.lowercased()
        if value.contains("dumbbell") || value.contains("kettlebell") { return .dumbbells }
        if value.contains("barbell") { return .barbell }
        if value.contains("cable") { return .cableMachine }
        if value.contains("smith") { return .smithMachine }
        if value.contains("bench") { return .bench }
        if value.contains("pull") { return .pullUpBar }
        if value.contains("treadmill") { return .treadmill }
        return .bodyweight
    }
}
