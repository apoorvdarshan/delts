import Foundation

struct FreeExerciseDBLoader {
    static let sourceName = "Free Exercise DB"

    static func load() -> [ExerciseLibraryItem] {
        guard
            let url = FreeExerciseDBAssetResolver.exercisesJSONURL(),
            let data = try? Data(contentsOf: url),
            let records = try? JSONDecoder().decode([FreeExerciseDBRecord].self, from: data)
        else {
            return []
        }

        return records
            .compactMap { record in
                Self.libraryItem(from: record)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func libraryItem(from record: FreeExerciseDBRecord) -> ExerciseLibraryItem? {
        let id = record.id.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = record.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !name.isEmpty else {
            return nil
        }

        let goal = goal(for: record)
        let level = experienceLevel(for: record.level ?? "")

        return ExerciseLibraryItem(
            id: id,
            name: name,
            muscleGroup: muscleGroup(for: record),
            equipment: equipment(for: record),
            level: level,
            rawLevel: record.level,
            goal: goal,
            sets: sets(for: goal, level: level),
            reps: reps(for: goal, level: level),
            restSeconds: restSeconds(for: goal),
            formTip: formTip(for: record),
            imagePaths: record.images,
            source: sourceName,
            force: record.force,
            mechanic: record.mechanic,
            category: record.category,
            rawEquipment: record.equipment,
            primaryMuscles: record.primaryMuscles,
            secondaryMuscles: record.secondaryMuscles,
            instructions: record.instructions
        )
    }

    private static func muscleGroup(for record: FreeExerciseDBRecord) -> MuscleGroup {
        let muscles = (record.primaryMuscles + record.secondaryMuscles)
            .map { $0.lowercased() }
        let joined = muscles.joined(separator: " ")

        if joined.contains("chest") {
            return .chest
        }
        if joined.contains("lats") || joined.contains("back") || joined.contains("traps") {
            return .back
        }
        if joined.contains("quadriceps") || joined.contains("hamstrings") || joined.contains("calves") || joined.contains("glutes") || joined.contains("adductors") || joined.contains("abductors") {
            return .legs
        }
        if joined.contains("shoulders") {
            return .shoulders
        }
        if joined.contains("biceps") || joined.contains("triceps") || joined.contains("forearms") {
            return .arms
        }
        if joined.contains("abdominals") {
            return .core
        }

        switch record.category?.lowercased() ?? "" {
        case "cardio", "plyometrics", "strongman", "olympic weightlifting":
            return .fullBody
        default:
            return .fullBody
        }
    }

    private static func equipment(for record: FreeExerciseDBRecord) -> Equipment {
        let equipment = record.equipment?.lowercased() ?? ""
        let name = record.name.lowercased()

        if name.contains("treadmill") {
            return .treadmill
        }
        if name.contains("pull-up") || name.contains("pull up") || name.contains("chin-up") || name.contains("chin up") {
            return .pullUpBar
        }
        if name.contains("leg press") {
            return .legPress
        }
        if name.contains("leg extension") {
            return .legExtension
        }
        if name.contains("leg curl") {
            return .legCurl
        }
        if name.contains("lat pulldown") || name.contains("pulldown") {
            return .latPulldown
        }
        if name.contains("chest press") {
            return .chestPress
        }
        if name.contains("shoulder press") && equipment.contains("machine") {
            return .shoulderPress
        }
        if name.contains("row") && equipment.contains("machine") {
            return .rowMachine
        }
        if equipment.contains("dumbbell") || equipment.contains("kettlebell") {
            return .dumbbells
        }
        if equipment.contains("barbell") || equipment.contains("e-z") {
            return .barbell
        }
        if equipment.contains("cable") {
            return .cableMachine
        }
        if equipment.contains("machine") {
            return .cableMachine
        }
        if name.contains("bench") {
            return .bench
        }

        return .bodyweight
    }

    private static func experienceLevel(for value: String) -> ExperienceLevel {
        switch value.lowercased() {
        case "beginner":
            return .beginner
        case "expert", "advanced":
            return .advanced
        default:
            return .intermediate
        }
    }

    private static func goal(for record: FreeExerciseDBRecord) -> FitnessGoal {
        switch record.category?.lowercased() ?? "" {
        case "cardio":
            return .endurance
        case "powerlifting", "strongman", "olympic weightlifting":
            return .maxStrength
        case "plyometrics":
            return .athleticPerformance
        case "stretching":
            return .generalFitness
        default:
            return record.level?.lowercased() == "beginner" ? .beginnerForm : .muscleGain
        }
    }

    private static func sets(for goal: FitnessGoal, level: ExperienceLevel) -> Int {
        switch goal {
        case .maxStrength:
            return level == .advanced ? 5 : 4
        case .endurance, .fatLoss, .athleticPerformance:
            return 4
        case .beginnerForm:
            return 3
        case .muscleGain, .generalFitness:
            return level == .advanced ? 4 : 3
        }
    }

    private static func reps(for goal: FitnessGoal, level: ExperienceLevel) -> String {
        switch goal {
        case .maxStrength:
            return level == .beginner ? "5-8" : "3-6"
        case .endurance:
            return "15-25"
        case .fatLoss, .athleticPerformance:
            return "30-45 sec"
        case .beginnerForm:
            return "8-12"
        case .muscleGain:
            return "8-12"
        case .generalFitness:
            return "10-15"
        }
    }

    private static func restSeconds(for goal: FitnessGoal) -> Int {
        switch goal {
        case .maxStrength:
            return 120
        case .endurance, .fatLoss, .athleticPerformance:
            return 45
        case .muscleGain:
            return 75
        case .beginnerForm, .generalFitness:
            return 60
        }
    }

    private static func formTip(for record: FreeExerciseDBRecord) -> String {
        record.instructions.first?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Move with control, keep your setup tight, and stop if form breaks."
    }
}

struct FreeExerciseDBRecord: Decodable {
    let id: String
    let name: String
    let force: String?
    let level: String?
    let mechanic: String?
    let equipment: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let category: String?
    let images: [String]
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
