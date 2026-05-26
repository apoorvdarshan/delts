import Foundation

struct ExerciseCategoryCount: Identifiable, Hashable {
    let category: String
    let count: Int

    var id: String { category }
}

struct ExerciseLibraryService {
    static let shared = ExerciseLibraryService()

    let exercises: [ExerciseLibraryItem]

    var availableForces: [String] {
        Self.sortedUnique(exercises.map(\.force))
    }

    var availableLevels: [String] {
        Self.sortedUnique(exercises.map(\.rawLevel))
    }

    var availableMechanics: [String] {
        Self.sortedUnique(exercises.map(\.mechanic))
    }

    var availableCategoryCounts: [ExerciseCategoryCount] {
        Dictionary(grouping: exercises, by: \.category)
            .map { ExerciseCategoryCount(category: $0.key, count: $0.value.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.category.localizedCaseInsensitiveCompare(rhs.category) == .orderedAscending
                }
                return lhs.count > rhs.count
            }
    }

    var availableRawEquipment: [String] {
        Self.sortedUnique(exercises.map(\.rawEquipment))
    }

    var availablePrimaryMuscles: [String] {
        Self.sortedUnique(exercises.flatMap(\.primaryMuscles))
    }

    var availableSecondaryMuscles: [String] {
        Self.sortedUnique(exercises.flatMap(\.secondaryMuscles))
    }

    init(exercises: [ExerciseLibraryItem]? = nil) {
        if let exercises {
            self.exercises = exercises
            return
        }

        self.exercises = FreeExerciseDBLoader.load()
    }

    func filtered(
        level: String?,
        rawEquipment: String?,
        primaryMuscle: String?,
        secondaryMuscle: String?,
        force: String?,
        mechanic: String?,
        category: String?,
        sort: ExerciseLibrarySort,
        searchText: String
    ) -> [ExerciseLibraryItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let filteredItems = exercises.filter { item in
            let matchesLevel = level == nil || item.rawLevel == level
            let matchesRawEquipment = rawEquipment == nil || item.rawEquipment == rawEquipment
            let matchesPrimaryMuscle = primaryMuscle == nil || item.primaryMuscles.contains(primaryMuscle ?? "")
            let matchesSecondaryMuscle = secondaryMuscle == nil || item.secondaryMuscles.contains(secondaryMuscle ?? "")
            let matchesForce = force == nil || item.force == force
            let matchesMechanic = mechanic == nil || item.mechanic == mechanic
            let matchesCategory = category == nil || item.category == category
            let matchesSearch = query.isEmpty || item.searchableText.contains(query)

            return matchesLevel &&
                matchesRawEquipment &&
                matchesPrimaryMuscle &&
                matchesSecondaryMuscle &&
                matchesForce &&
                matchesMechanic &&
                matchesCategory &&
                matchesSearch
        }

        return filteredItems.sorted { lhs, rhs in
            switch sort {
            case .name:
                return lhs.name < rhs.name
            case .level:
                if Self.levelSortRank(lhs.rawLevel) == Self.levelSortRank(rhs.rawLevel) {
                    return lhs.name < rhs.name
                }
                return Self.levelSortRank(lhs.rawLevel) < Self.levelSortRank(rhs.rawLevel)
            case .primaryMuscles:
                return Self.compare(lhs.primaryMusclesTitle, rhs.primaryMusclesTitle, lhsName: lhs.name, rhsName: rhs.name)
            case .secondaryMuscles:
                return Self.compare(lhs.secondaryMusclesTitle, rhs.secondaryMusclesTitle, lhsName: lhs.name, rhsName: rhs.name)
            case .category:
                return Self.compare(lhs.category, rhs.category, lhsName: lhs.name, rhsName: rhs.name)
            case .force:
                return Self.compare(lhs.force, rhs.force, lhsName: lhs.name, rhsName: rhs.name)
            case .mechanic:
                return Self.compare(lhs.mechanic, rhs.mechanic, lhsName: lhs.name, rhsName: rhs.name)
            case .rawEquipment:
                return Self.compare(lhs.rawEquipment, rhs.rawEquipment, lhsName: lhs.name, rhsName: rhs.name)
            }
        }
    }

    private static func sortedUnique(_ values: [String]) -> [String] {
        Array(Set(values.filter { !$0.isEmpty }))
            .sorted { lhs, rhs in
                if levelSortRank(lhs) == levelSortRank(rhs) {
                    return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                }
                return levelSortRank(lhs) < levelSortRank(rhs)
            }
    }

    private static func compare(_ lhs: String, _ rhs: String, lhsName: String, rhsName: String) -> Bool {
        if lhs == rhs {
            return lhsName < rhsName
        }
        return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }

    private static func levelSortRank(_ level: String) -> Int {
        switch level.lowercased() {
        case "beginner": return 0
        case "intermediate": return 1
        case "expert", "advanced": return 2
        default: return 3
        }
    }
}
