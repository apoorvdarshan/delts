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
    let imagePaths: [String]
    let source: String
    let force: String
    let mechanic: String
    let category: String
    let rawEquipment: String
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]

    init(
        id: String,
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        level: ExperienceLevel,
        goal: FitnessGoal,
        sets: Int,
        reps: String,
        restSeconds: Int,
        formTip: String,
        imagePaths: [String] = [],
        source: String = "delts",
        force: String? = nil,
        mechanic: String? = nil,
        category: String? = nil,
        rawEquipment: String? = nil,
        primaryMuscles: [String] = [],
        secondaryMuscles: [String] = [],
        instructions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.level = level
        self.goal = goal
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.formTip = formTip
        self.imagePaths = imagePaths
        self.source = source
        self.force = Self.metadataTitle(force)
        self.mechanic = Self.metadataTitle(mechanic)
        self.category = Self.metadataTitle(category)
        self.rawEquipment = Self.metadataTitle(rawEquipment)
        self.primaryMuscles = Self.metadataTitles(primaryMuscles)
        self.secondaryMuscles = Self.metadataTitles(secondaryMuscles)
        let cleanedInstructions = instructions.compactMap { $0.trimmed.nilIfEmpty }
        self.instructions = cleanedInstructions.isEmpty ? [formTip.trimmed].compactMap { $0.nilIfEmpty } : cleanedInstructions
    }

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

    var primaryMusclesTitle: String {
        primaryMuscles.isEmpty ? "Unspecified" : primaryMuscles.joined(separator: ", ")
    }

    var secondaryMusclesTitle: String {
        secondaryMuscles.isEmpty ? "None" : secondaryMuscles.joined(separator: ", ")
    }

    var databaseMetadataSummary: String {
        [category, force, mechanic]
            .filter { $0 != "Unspecified" }
            .joined(separator: " - ")
            .nilIfEmpty ?? "Database metadata"
    }

    var searchableText: String {
        [
            name,
            muscleGroup.title,
            equipment.title,
            level.title,
            goal.title,
            machineLabel,
            formTip,
            source,
            force,
            mechanic,
            category,
            rawEquipment,
            primaryMuscles.joined(separator: " "),
            secondaryMuscles.joined(separator: " "),
            instructions.joined(separator: " ")
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

    nonisolated private static func metadataTitles(_ values: [String]) -> [String] {
        values
            .map(metadataTitle)
            .filter { $0 != "Unspecified" }
    }

    nonisolated private static func metadataTitle(_ value: String?) -> String {
        guard let value else { return "Unspecified" }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Unspecified" }

        return trimmed
            .split(separator: " ")
            .map { word in
                word
                    .split(separator: "-", omittingEmptySubsequences: false)
                    .map { segment in
                        guard let first = segment.first else { return "" }
                        return first.uppercased() + segment.dropFirst().lowercased()
                    }
                    .joined(separator: "-")
            }
            .joined(separator: " ")
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
    case name = "Name"
    case level = "Level"
    case primaryMuscles = "Primary Muscles"
    case secondaryMuscles = "Secondary Muscles"
    case category = "Category"
    case force = "Force"
    case mechanic = "Mechanic"
    case rawEquipment = "Equipment"

    var id: String { rawValue }
    var title: String { rawValue }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
