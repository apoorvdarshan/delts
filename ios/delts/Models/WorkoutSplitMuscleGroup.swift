import Foundation

struct WorkoutSplitMuscleGroup: Identifiable, Hashable {
    let title: String
    let muscles: Set<String>

    var id: String { title }

    static func groups(for split: WorkoutSplit) -> [WorkoutSplitMuscleGroup] {
        switch split {
        case .fullBody:
            return []
        case .upperLower:
            return [
                group("Upper", ["Biceps", "Chest", "Forearms", "Lats", "Middle Back", "Neck", "Shoulders", "Traps", "Triceps"]),
                group("Lower", ["Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Lower Back", "Quadriceps"]),
                group("Core", ["Abdominals"])
            ]
        case .pushPullLegs:
            return [
                group("Push", ["Chest", "Shoulders", "Triceps"]),
                group("Pull", ["Biceps", "Forearms", "Lats", "Middle Back", "Traps", "Neck"]),
                group("Legs", ["Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Lower Back", "Quadriceps"]),
                group("Core", ["Abdominals"])
            ]
        case .broSplit:
            return [
                group("Chest", ["Chest"]),
                group("Back", ["Lats", "Middle Back", "Lower Back", "Traps"]),
                group("Shoulders", ["Shoulders", "Traps"]),
                group("Arms", ["Biceps", "Triceps", "Forearms"]),
                group("Legs", ["Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Quadriceps"]),
                group("Core", ["Abdominals"])
            ]
        case .arnoldSplit:
            return [
                group("Chest + Back", ["Chest", "Lats", "Middle Back", "Lower Back", "Traps"]),
                group("Shoulders + Arms", ["Shoulders", "Biceps", "Triceps", "Forearms", "Neck"]),
                group("Legs", ["Abductors", "Adductors", "Calves", "Glutes", "Hamstrings", "Quadriceps"]),
                group("Core", ["Abdominals"])
            ]
        case .pushPull:
            return [
                group("Push", ["Chest", "Shoulders", "Triceps", "Quadriceps", "Calves"]),
                group("Pull", ["Biceps", "Forearms", "Lats", "Middle Back", "Traps", "Glutes", "Hamstrings", "Lower Back"]),
                group("Accessory/Core", ["Abdominals", "Abductors", "Adductors", "Neck"])
            ]
        case .antagonistSplit:
            return [
                group("Chest + Back", ["Chest", "Lats", "Middle Back", "Lower Back", "Traps"]),
                group("Biceps + Triceps", ["Biceps", "Triceps", "Forearms"]),
                group("Quads + Hamstrings/Glutes", ["Quadriceps", "Hamstrings", "Glutes"]),
                group("Shoulders + Lats/Traps", ["Shoulders", "Lats", "Traps"]),
                group("Core/Accessory", ["Abdominals", "Abductors", "Adductors", "Calves", "Neck"])
            ]
        case .hybridSplit:
            return [
                group("Strength/Compound", ["Chest", "Lats", "Middle Back", "Lower Back", "Glutes", "Hamstrings", "Quadriceps", "Shoulders", "Traps"]),
                group("Accessory/Hypertrophy", ["Biceps", "Triceps", "Forearms", "Calves", "Abductors", "Adductors", "Abdominals", "Neck"])
            ]
        case .custom:
            return []
        }
    }

    private static func group(_ title: String, _ muscles: Set<String>) -> WorkoutSplitMuscleGroup {
        WorkoutSplitMuscleGroup(title: title, muscles: muscles)
    }
}
