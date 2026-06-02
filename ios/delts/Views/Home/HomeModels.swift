import Foundation

enum WorkoutPickerSource: String, CaseIterable, Identifiable {
    case dataset = "Dataset"
    case saved = "Saved"

    var id: String { rawValue }
}

struct WorkoutPickerContext: Identifiable, Hashable {
    static let all = WorkoutPickerContext(title: "All Workouts", muscles: [])
    static let saved = WorkoutPickerContext(title: "Saved", muscles: [])

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
        if title.contains("saved") { return "bookmark.fill" }
        return "square.grid.2x2"
    }
}

struct WorkoutDayPlan: Codable, Identifiable, Hashable {
    var dateKey: String
    var exercises: [PlannedRoutineExercise] = []

    var id: String { dateKey }
}

struct PlannedSetFocus: Hashable {
    let exerciseID: UUID
    let setIndex: Int
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
    var setReps: [String] = [""]

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

    var normalizedSetReps: [String] {
        let count = max(sets, 1)
        var values = setReps
        if values.isEmpty {
            values = Array(repeating: reps, count: count)
        }
        if values.count < count {
            values.append(contentsOf: Array(repeating: values.last ?? reps, count: count - values.count))
        }
        if values.count > count {
            values = Array(values.prefix(count))
        }
        return values
    }

    var repsSummary: String {
        Self.summary(for: normalizedSetReps)
    }

    mutating func setSetCount(_ count: Int) {
        let clampedCount = min(max(count, 1), 12)
        var values = normalizedSetReps
        if values.count < clampedCount {
            values.append(contentsOf: Array(repeating: "", count: clampedCount - values.count))
        }
        values = Array(values.prefix(clampedCount))
        sets = clampedCount
        setReps = values
        reps = Self.summary(for: values)
    }

    mutating func setReps(_ value: String, forSet index: Int) {
        var values = normalizedSetReps
        guard values.indices.contains(index) else { return }
        values[index] = value
        setReps = values
        reps = Self.summary(for: values)
    }

    private mutating func normalizeStoredSets() {
        setSetCount(sets)
    }

    static func summary(for values: [String]) -> String {
        let trimmed = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let filled = trimmed.filter { !$0.isEmpty }
        guard !filled.isEmpty else { return "" }
        if filled.count == trimmed.count, Set(filled).count == 1 {
            return filled[0]
        }
        return trimmed.enumerated()
            .map { index, value in
                value.isEmpty ? "S\(index + 1): -" : "S\(index + 1): \(value)"
            }
            .joined(separator: ", ")
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case itemID
        case name
        case primaryMuscles
        case rawEquipment
        case rawLevel
        case category
        case imagePaths
        case instructions
        case sets
        case reps
        case setReps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        itemID = try container.decode(String.self, forKey: .itemID)
        name = try container.decode(String.self, forKey: .name)
        primaryMuscles = try container.decodeIfPresent([String].self, forKey: .primaryMuscles) ?? []
        rawEquipment = try container.decodeIfPresent(String.self, forKey: .rawEquipment) ?? "Unspecified"
        rawLevel = try container.decodeIfPresent(String.self, forKey: .rawLevel) ?? "Unknown"
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        imagePaths = try container.decodeIfPresent([String].self, forKey: .imagePaths) ?? []
        instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        sets = try container.decodeIfPresent(Int.self, forKey: .sets) ?? 1
        reps = try container.decodeIfPresent(String.self, forKey: .reps) ?? ""
        setReps = try container.decodeIfPresent([String].self, forKey: .setReps) ?? []
        normalizeStoredSets()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(itemID, forKey: .itemID)
        try container.encode(name, forKey: .name)
        try container.encode(primaryMuscles, forKey: .primaryMuscles)
        try container.encode(rawEquipment, forKey: .rawEquipment)
        try container.encode(rawLevel, forKey: .rawLevel)
        try container.encode(category, forKey: .category)
        try container.encode(imagePaths, forKey: .imagePaths)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(max(sets, 1), forKey: .sets)
        try container.encode(repsSummary, forKey: .reps)
        try container.encode(normalizedSetReps, forKey: .setReps)
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
                    reps: exercise.repsSummary,
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
