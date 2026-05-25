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

        let bundledExercises = FreeExerciseDBLoader.load()
        self.exercises = bundledExercises.isEmpty ? Self.fallbackExercises : bundledExercises
    }

    private static let fallbackExercises: [ExerciseLibraryItem] = [
        .item("bench_press_barbell", "Barbell Bench Press", .chest, .barbell, .intermediate, .muscleGain, 4, "6-10", 90, "Pack shoulders down, touch the lower chest, and press through a stable arch."),
        .item("incline_db_press", "Incline Dumbbell Press", .chest, .dumbbells, .intermediate, .muscleGain, 4, "8-12", 75, "Keep elbows under wrists and press slightly back toward the top of the bench."),
        .item("chest_press_machine", "Chest Press Machine", .chest, .chestPress, .beginner, .beginnerForm, 3, "10-12", 60, "Adjust the seat so handles start around mid-chest and avoid shrugging."),
        .item("cable_fly", "Cable Fly", .chest, .cableMachine, .intermediate, .muscleGain, 3, "12-15", 45, "Keep a soft elbow bend and bring hands together without losing chest tension."),
        .item("push_up", "Push-Up", .chest, .bodyweight, .beginner, .generalFitness, 3, "8-15", 45, "Brace abs and keep the body moving as one rigid plank."),
        .item("smith_incline_press", "Smith Machine Incline Press", .chest, .smithMachine, .intermediate, .maxStrength, 4, "6-8", 90, "Set the bench so the bar tracks over upper chest without flaring hard."),
        .item("bench_dip", "Bench Dip", .arms, .bench, .beginner, .muscleGain, 3, "10-15", 60, "Keep shoulders depressed and stop before the front shoulder pinches."),
        .item("dumbbell_pullover", "Dumbbell Pullover", .chest, .dumbbells, .intermediate, .generalFitness, 3, "10-12", 60, "Keep ribs down and move through the shoulders rather than the low back."),

        .item("lat_pulldown", "Lat Pulldown", .back, .latPulldown, .beginner, .muscleGain, 4, "8-12", 75, "Drive elbows to your ribs and keep the torso tall."),
        .item("seated_cable_row", "Seated Cable Row", .back, .rowMachine, .beginner, .muscleGain, 4, "10-12", 60, "Pause with shoulder blades packed before controlling the return."),
        .item("pull_up", "Pull-Up", .back, .pullUpBar, .advanced, .maxStrength, 5, "3-8", 120, "Start from a dead hang and pull chest toward the bar."),
        .item("barbell_row", "Barbell Row", .back, .barbell, .intermediate, .maxStrength, 4, "6-10", 90, "Hinge hard, keep lats tight, and pull the bar toward the lower ribs."),
        .item("one_arm_db_row", "One-Arm Dumbbell Row", .back, .dumbbells, .beginner, .muscleGain, 3, "10-12", 60, "Pull elbow toward the hip without rotating the torso."),
        .item("straight_arm_pulldown", "Straight-Arm Pulldown", .back, .cableMachine, .intermediate, .muscleGain, 3, "12-15", 45, "Keep arms long and initiate by pulling the shoulders down."),
        .item("smith_row", "Smith Machine Row", .back, .smithMachine, .intermediate, .muscleGain, 4, "8-12", 75, "Set the bar low, hinge, and row with a fixed torso angle."),
        .item("treadmill_farmer_walk", "Treadmill Farmer Walk", .fullBody, .treadmill, .advanced, .athleticPerformance, 4, "45 sec", 60, "Walk tall with heavy handles and steady breathing."),

        .item("back_squat", "Back Squat", .legs, .barbell, .intermediate, .maxStrength, 5, "3-6", 150, "Brace before every rep and keep pressure through the mid-foot."),
        .item("goblet_squat", "Goblet Squat", .legs, .dumbbells, .beginner, .beginnerForm, 3, "10-12", 60, "Hold the dumbbell high and sit between your hips."),
        .item("leg_press", "Leg Press", .legs, .legPress, .beginner, .muscleGain, 4, "10-15", 75, "Use deep range without letting hips roll off the pad."),
        .item("leg_extension", "Leg Extension", .legs, .legExtension, .beginner, .muscleGain, 3, "12-15", 45, "Pause at lockout and lower slowly."),
        .item("lying_leg_curl", "Lying Leg Curl", .legs, .legCurl, .beginner, .muscleGain, 3, "10-15", 60, "Keep hips pinned and curl through hamstrings."),
        .item("romanian_deadlift", "Romanian Deadlift", .legs, .barbell, .intermediate, .muscleGain, 4, "8-10", 90, "Push hips back until hamstrings load, then stand tall."),
        .item("smith_split_squat", "Smith Machine Split Squat", .legs, .smithMachine, .intermediate, .muscleGain, 3, "8-12", 75, "Keep the front foot planted and descend under control."),
        .item("walking_lunge", "Walking Lunge", .legs, .dumbbells, .intermediate, .fatLoss, 3, "12 each", 45, "Take controlled steps and keep the front knee tracking over toes."),

        .item("overhead_press", "Overhead Press", .shoulders, .barbell, .intermediate, .maxStrength, 5, "3-6", 150, "Squeeze glutes and press through a stacked torso."),
        .item("dumbbell_lateral_raise", "Dumbbell Lateral Raise", .shoulders, .dumbbells, .beginner, .muscleGain, 4, "12-18", 45, "Lead with elbows and stop around shoulder height."),
        .item("shoulder_press_machine", "Shoulder Press Machine", .shoulders, .shoulderPress, .beginner, .beginnerForm, 3, "10-12", 60, "Keep ribs down and avoid bouncing from the bottom."),
        .item("cable_face_pull", "Cable Face Pull", .shoulders, .cableMachine, .beginner, .generalFitness, 3, "12-15", 45, "Pull rope toward eye level with thumbs traveling back."),
        .item("arnold_press", "Arnold Press", .shoulders, .dumbbells, .advanced, .muscleGain, 4, "8-12", 75, "Rotate smoothly and keep tension through the full press."),
        .item("smith_shoulder_press", "Smith Machine Shoulder Press", .shoulders, .smithMachine, .intermediate, .maxStrength, 4, "6-8", 90, "Set the bench upright and press without overextending the low back."),
        .item("rear_delt_fly", "Rear Delt Fly", .shoulders, .dumbbells, .beginner, .muscleGain, 3, "12-15", 45, "Move through the rear delts and avoid shrugging."),
        .item("pike_push_up", "Pike Push-Up", .shoulders, .bodyweight, .intermediate, .generalFitness, 3, "6-12", 60, "Keep hips high and lower crown toward the floor."),

        .item("barbell_curl", "Barbell Curl", .arms, .barbell, .beginner, .muscleGain, 4, "8-12", 60, "Lock elbows beside the ribs and avoid swinging."),
        .item("hammer_curl", "Dumbbell Hammer Curl", .arms, .dumbbells, .beginner, .muscleGain, 3, "10-12", 45, "Keep wrists neutral and control the lowering phase."),
        .item("cable_triceps_pressdown", "Cable Triceps Pressdown", .arms, .cableMachine, .beginner, .muscleGain, 4, "10-15", 45, "Pin elbows and finish with hard triceps extension."),
        .item("overhead_cable_extension", "Overhead Cable Extension", .arms, .cableMachine, .intermediate, .muscleGain, 3, "10-15", 60, "Keep elbows high and stretch triceps without arching."),
        .item("close_grip_bench_press", "Close-Grip Bench Press", .arms, .barbell, .intermediate, .maxStrength, 4, "5-8", 90, "Use a shoulder-width grip and keep elbows tucked."),
        .item("preacher_curl_machine", "Machine Preacher Curl", .arms, .cableMachine, .beginner, .beginnerForm, 3, "10-12", 60, "Keep upper arms glued to the pad and do not bounce."),
        .item("close_grip_push_up", "Close-Grip Push-Up", .arms, .bodyweight, .beginner, .generalFitness, 3, "8-15", 45, "Keep elbows tucked and move as one plank."),
        .item("reverse_curl", "Reverse Curl", .arms, .barbell, .intermediate, .generalFitness, 3, "10-12", 45, "Hold wrists straight and lift without shoulder swing."),

        .item("plank", "Plank", .core, .bodyweight, .beginner, .beginnerForm, 3, "30-60 sec", 45, "Tuck pelvis slightly and breathe behind the brace."),
        .item("cable_crunch", "Cable Crunch", .core, .cableMachine, .beginner, .muscleGain, 3, "12-15", 45, "Round through the abs instead of pulling with arms."),
        .item("hanging_knee_raise", "Hanging Knee Raise", .core, .pullUpBar, .intermediate, .muscleGain, 3, "10-15", 60, "Posteriorly tilt pelvis at the top of each rep."),
        .item("dead_bug", "Dead Bug", .core, .bodyweight, .beginner, .beginnerForm, 3, "8 each", 45, "Keep low back heavy against the floor."),
        .item("weighted_sit_up", "Weighted Sit-Up", .core, .dumbbells, .intermediate, .muscleGain, 3, "10-12", 60, "Move slowly and keep tension through the abs."),
        .item("pallof_press", "Pallof Press", .core, .cableMachine, .beginner, .athleticPerformance, 3, "10 each", 45, "Resist rotation and keep ribs stacked over hips."),
        .item("ab_wheel_rollout", "Ab Wheel Rollout", .core, .bodyweight, .advanced, .maxStrength, 4, "6-10", 75, "Reach only as far as you can keep the low back locked."),
        .item("mountain_climber", "Mountain Climber", .core, .bodyweight, .beginner, .fatLoss, 4, "30 sec", 30, "Drive knees fast while shoulders stay stacked over hands."),

        .item("kettlebell_style_db_swing", "Dumbbell Swing", .fullBody, .dumbbells, .intermediate, .athleticPerformance, 4, "12-20", 45, "Hinge explosively and let hips, not arms, drive the bell."),
        .item("thruster", "Dumbbell Thruster", .fullBody, .dumbbells, .advanced, .fatLoss, 4, "8-12", 60, "Squat deep and use leg drive to launch the press."),
        .item("deadlift", "Deadlift", .fullBody, .barbell, .advanced, .maxStrength, 5, "3-5", 150, "Wedge hips to the bar and push the floor away."),
        .item("burpee", "Burpee", .fullBody, .bodyweight, .intermediate, .fatLoss, 4, "8-15", 45, "Land softly and keep reps crisp rather than sloppy."),
        .item("incline_treadmill_walk", "Incline Treadmill Walk", .fullBody, .treadmill, .beginner, .endurance, 1, "15-30 min", 0, "Stay tall, keep cadence smooth, and breathe steadily."),
        .item("cable_woodchop", "Cable Woodchop", .fullBody, .cableMachine, .intermediate, .athleticPerformance, 3, "10 each", 45, "Rotate through the torso while hips stay controlled."),
        .item("smith_machine_squat", "Smith Machine Squat", .fullBody, .smithMachine, .beginner, .beginnerForm, 3, "10-12", 75, "Set stance so knees track cleanly and torso stays braced."),
        .item("pull_push_circuit", "Pull-Push Circuit", .fullBody, .bodyweight, .intermediate, .endurance, 4, "45 sec", 30, "Alternate clean pulling and pressing reps without rushing form.")
    ]

    func filtered(
        muscleGroups: Set<MuscleGroup>,
        level: ExperienceLevel?,
        equipment: Equipment?,
        equipmentFamily: ExerciseEquipmentFamily,
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
            let matchesMuscle = muscleGroups.isEmpty || muscleGroups.contains(item.muscleGroup)
            let matchesLevel = level == nil || item.level == level
            let matchesEquipment = equipment == nil || item.equipment == equipment
            let matchesFamily = equipmentFamily == .all || item.equipmentFamily == equipmentFamily
            let matchesRawEquipment = rawEquipment == nil || item.rawEquipment == rawEquipment
            let matchesPrimaryMuscle = primaryMuscle == nil || item.primaryMuscles.contains(primaryMuscle ?? "")
            let matchesSecondaryMuscle = secondaryMuscle == nil || item.secondaryMuscles.contains(secondaryMuscle ?? "")
            let matchesForce = force == nil || item.force == force
            let matchesMechanic = mechanic == nil || item.mechanic == mechanic
            let matchesCategory = category == nil || item.category == category
            let matchesSearch = query.isEmpty || item.searchableText.contains(query)

            return matchesMuscle &&
                matchesLevel &&
                matchesEquipment &&
                matchesFamily &&
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
            case .bodyPart:
                if lhs.muscleGroup.title == rhs.muscleGroup.title {
                    return lhs.name < rhs.name
                }
                return lhs.muscleGroup.title < rhs.muscleGroup.title
            case .name:
                return lhs.name < rhs.name
            case .level:
                if lhs.level.sortRank == rhs.level.sortRank {
                    return lhs.name < rhs.name
                }
                return lhs.level.sortRank < rhs.level.sortRank
            case .equipment:
                if lhs.equipment.title == rhs.equipment.title {
                    return lhs.name < rhs.name
                }
                return lhs.equipment.title < rhs.equipment.title
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

    func makePlan(from items: [ExerciseLibraryItem]) -> WorkoutPlan {
        let selectedItems = Array(items.prefix(8))
        let primaryMuscle = selectedItems.first?.muscleGroup ?? .fullBody
        let primaryGoal = selectedItems.first?.goal ?? .generalFitness
        let duration = selectedItems.count <= 4 ? 30 : selectedItems.count <= 6 ? 45 : 60

        let exercises = selectedItems.enumerated().map { index, item in
            item.workoutExercise(orderIndex: index)
        }

        return WorkoutPlan(
            title: libraryPlanTitle(for: selectedItems),
            summary: "Built from the filtered exercise library with \(selectedItems.count) movements.",
            muscleGroup: primaryMuscle,
            goal: primaryGoal,
            durationMinutes: duration,
            generatedByAI: false,
            exercises: exercises
        )
    }

    private func libraryPlanTitle(for items: [ExerciseLibraryItem]) -> String {
        guard let first = items.first else {
            return "Library Workout"
        }

        let bodyParts = Set(items.map(\.muscleGroup)).count
        if bodyParts == 1 {
            return "\(first.muscleGroup.title) Library Workout"
        }

        return "Custom Library Workout"
    }

    private static func sortedUnique(_ values: [String]) -> [String] {
        Array(Set(values.filter { !$0.isEmpty }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private static func compare(_ lhs: String, _ rhs: String, lhsName: String, rhsName: String) -> Bool {
        if lhs == rhs {
            return lhsName < rhsName
        }
        return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }
}

private extension ExperienceLevel {
    var sortRank: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }
}

private extension ExerciseLibraryItem {
    static func item(
        _ id: String,
        _ name: String,
        _ muscleGroup: MuscleGroup,
        _ equipment: Equipment,
        _ level: ExperienceLevel,
        _ goal: FitnessGoal,
        _ sets: Int,
        _ reps: String,
        _ restSeconds: Int,
        _ formTip: String
    ) -> ExerciseLibraryItem {
        ExerciseLibraryItem(
            id: id,
            name: name,
            muscleGroup: muscleGroup,
            equipment: equipment,
            level: level,
            goal: goal,
            sets: sets,
            reps: reps,
            restSeconds: restSeconds,
            formTip: formTip
        )
    }
}
