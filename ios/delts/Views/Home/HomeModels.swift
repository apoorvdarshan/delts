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

struct PlannedWorkoutDetailRoute: Identifiable, Hashable {
    var exerciseID: UUID

    var id: UUID { exerciseID }
}

struct PlannedSetFocus: Hashable {
    enum Field: Hashable {
        case reps
        case rpe
    }

    let exerciseID: UUID
    let setIndex: Int
    let field: Field
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
    var setRPE: [String] = [""]
    var setCompletedAt: [Date?] = [nil]
    var addedAt: Date = Date()
    var startedAt: Date?
    var completedAt: Date?
    var isDone: Bool = false

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
        normalizedValues(setReps, fallback: reps)
    }

    var normalizedSetRPE: [String] {
        let count = max(sets, 1)
        var values = setRPE
        if values.count < count {
            values.append(contentsOf: Array(repeating: "", count: count - values.count))
        }
        if values.count > count {
            values = Array(values.prefix(count))
        }
        return values
    }

    var normalizedSetCompletedAt: [Date?] {
        let count = max(sets, 1)
        var values = setCompletedAt
        if values.count < count {
            values.append(contentsOf: Array(repeating: nil, count: count - values.count))
        }
        if values.count > count {
            values = Array(values.prefix(count))
        }
        return values
    }

    var firstSetCompletedAt: Date? {
        normalizedSetCompletedAt.compactMap(\.self).first
    }

    var lastSetCompletedAt: Date? {
        normalizedSetCompletedAt.compactMap(\.self).last
    }

    var workoutStartReference: Date? {
        startedAt ?? firstSetCompletedAt
    }

    var workoutEndReference: Date? {
        completedAt ?? lastSetCompletedAt
    }

    private func normalizedValues(_ storedValues: [String], fallback: String) -> [String] {
        let count = max(sets, 1)
        var values = storedValues
        if values.isEmpty {
            values = Array(repeating: fallback, count: count)
        }
        if values.count < count {
            values.append(contentsOf: Array(repeating: values.last ?? fallback, count: count - values.count))
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
        var repValues = normalizedSetReps
        var rpeValues = normalizedSetRPE
        var completedValues = normalizedSetCompletedAt
        if repValues.count < clampedCount {
            repValues.append(contentsOf: Array(repeating: "", count: clampedCount - repValues.count))
        }
        if rpeValues.count < clampedCount {
            rpeValues.append(contentsOf: Array(repeating: "", count: clampedCount - rpeValues.count))
        }
        if completedValues.count < clampedCount {
            completedValues.append(contentsOf: Array(repeating: nil, count: clampedCount - completedValues.count))
        }
        repValues = Array(repValues.prefix(clampedCount))
        rpeValues = Array(rpeValues.prefix(clampedCount))
        completedValues = Array(completedValues.prefix(clampedCount))
        sets = clampedCount
        setReps = repValues
        setRPE = rpeValues
        setCompletedAt = completedValues
        reps = Self.summary(for: repValues)
    }

    mutating func setReps(_ value: String, forSet index: Int) {
        var values = normalizedSetReps
        guard values.indices.contains(index) else { return }
        values[index] = value
        setReps = values
        reps = Self.summary(for: values)
    }

    mutating func setRPE(_ value: String, forSet index: Int) {
        var values = normalizedSetRPE
        guard values.indices.contains(index) else { return }
        values[index] = value
        setRPE = values
    }

    mutating func start(at date: Date = Date()) {
        if startedAt == nil {
            startedAt = date
        }
    }

    mutating func setDone(_ isDone: Bool, at date: Date = Date()) {
        self.isDone = isDone
        if isDone {
            start(at: date)
            completedAt = date
        } else {
            completedAt = nil
        }
    }

    mutating func syncSetCompletionTimestamp(forSet index: Int, at date: Date = Date()) {
        var completedValues = normalizedSetCompletedAt
        guard completedValues.indices.contains(index) else { return }

        let reps = normalizedSetReps
        let rpe = normalizedSetRPE
        let repsValue = reps.indices.contains(index) ? reps[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let rpeValue = rpe.indices.contains(index) ? rpe[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        let hasLoggedSet = !repsValue.isEmpty || !rpeValue.isEmpty

        if hasLoggedSet {
            start(at: date)
            if completedValues[index] == nil {
                completedValues[index] = date
            }
        } else {
            completedValues[index] = nil
        }
        setCompletedAt = completedValues
    }

    func setElapsedSeconds(forSet index: Int) -> Int? {
        let completedValues = normalizedSetCompletedAt
        guard completedValues.indices.contains(index),
              let completedAt = completedValues[index]
        else { return nil }

        let referenceDate: Date?
        if index == 0 {
            referenceDate = startedAt
        } else {
            referenceDate = completedValues[index - 1]
        }
        guard let referenceDate else { return nil }
        return max(0, Int(completedAt.timeIntervalSince(referenceDate)))
    }

    func setWorkoutElapsedSeconds(forSet index: Int) -> Int? {
        let completedValues = normalizedSetCompletedAt
        guard completedValues.indices.contains(index),
              let startedAt,
              let completedAt = completedValues[index]
        else { return nil }
        return max(0, Int(completedAt.timeIntervalSince(startedAt)))
    }

    func restSeconds(beforeSet index: Int) -> Int? {
        let completedValues = normalizedSetCompletedAt
        guard index > 0,
              completedValues.indices.contains(index),
              completedValues.indices.contains(index - 1),
              let previousCompletedAt = completedValues[index - 1],
              let currentCompletedAt = completedValues[index]
        else { return nil }
        return max(0, Int(currentCompletedAt.timeIntervalSince(previousCompletedAt)))
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
        case setRPE
        case setCompletedAt
        case addedAt
        case startedAt
        case completedAt
        case isDone
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
        setRPE = try container.decodeIfPresent([String].self, forKey: .setRPE) ?? []
        setCompletedAt = try container.decodeIfPresent([Date?].self, forKey: .setCompletedAt) ?? []
        addedAt = try container.decodeIfPresent(Date.self, forKey: .addedAt) ?? Date()
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
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
        try container.encode(normalizedSetRPE, forKey: .setRPE)
        try container.encode(normalizedSetCompletedAt, forKey: .setCompletedAt)
        try container.encode(addedAt, forKey: .addedAt)
        try container.encodeIfPresent(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(isDone, forKey: .isDone)
    }
}

enum WorkoutDayPlanStore {
    private static let key = "delts.dailyWorkoutPlans.v1"
    static let didChangeNotification = Notification.Name("WorkoutDayPlanStore.didChange")

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

    static func notifyChanged() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
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
