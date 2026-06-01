import Foundation

struct ExerciseFilterState: Codable, Equatable {
    var searchText = ""
    var splitGroups: Set<String> = []
    var levels: Set<String> = []
    var rawEquipment: Set<String> = []
    var primaryMuscles: Set<String> = []
    var secondaryMuscles: Set<String> = []
    var forces: Set<String> = []
    var mechanics: Set<String> = []
    var categories: Set<String> = []
    var sort: ExerciseLibrarySort = .name

    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
            !splitGroups.isEmpty ||
            !levels.isEmpty ||
            !rawEquipment.isEmpty ||
            !primaryMuscles.isEmpty ||
            !secondaryMuscles.isEmpty ||
            !forces.isEmpty ||
            !mechanics.isEmpty ||
            !categories.isEmpty ||
            sort != .name
    }
}

enum ExerciseFilterStateStore {
    static let workoutsKey = "delts.workouts.filterState"

    static func startPickerKey(for contextID: String) -> String {
        "delts.startPicker.filterState.\(contextID)"
    }

    static func load(key: String) -> ExerciseFilterState {
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(ExerciseFilterState.self, from: data) else {
            return ExerciseFilterState()
        }
        return state
    }

    static func save(_ state: ExerciseFilterState, key: String) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
