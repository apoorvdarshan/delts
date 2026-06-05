import Foundation

struct LocalWorkoutGenerator {
    private struct ExerciseTemplate {
        let name: String
        let muscle: MuscleGroup
        let equipment: Equipment
        let formTip: String
    }

    func generate(
        profile: UserProfile?,
        muscleGroup: MuscleGroup,
        goal: FitnessGoal,
        equipment selectedEquipment: Set<Equipment>,
        durationRange: WorkoutDurationRangeOption,
        experience: ExperienceLevel
    ) -> WorkoutPlan {
        let availableEquipment = selectedEquipment.isEmpty ? (profile?.availableEquipment ?? [.bodyweight]) : selectedEquipment
        let duration = durationRange.targetMinutes
        let exerciseCount = targetExerciseCount(for: duration)
        let templates = candidateTemplates(for: muscleGroup, equipment: availableEquipment, count: exerciseCount)
        let prescription = prescription(for: goal, experience: experience)

        let exercises = templates.enumerated().map { index, template in
            WorkoutExercise(
                orderIndex: index,
                name: template.name,
                targetMuscle: template.muscle,
                equipment: template.equipment,
                sets: prescription.sets,
                reps: prescription.reps,
                restSeconds: prescription.restSeconds,
                formTip: template.formTip,
                difficulty: difficulty(for: experience, index: index)
            )
        }

        return WorkoutPlan(
            title: "\(muscleGroup.title) \(goal.title)",
            summary: "\(durationRange.title) \(experience.title.lowercased()) plan tuned for \(goal.title.lowercased()).",
            muscleGroup: muscleGroup,
            goal: goal,
            durationMinutes: duration,
            generatedByAI: false,
            exercises: exercises
        )
    }

    private func targetExerciseCount(for duration: Int) -> Int {
        switch duration {
        case ..<35: return 4
        case ..<50: return 5
        case ..<75: return 6
        case ..<105: return 8
        case ..<135: return 10
        default: return 12
        }
    }

    private func prescription(for goal: FitnessGoal, experience: ExperienceLevel) -> (sets: Int, reps: String, restSeconds: Int) {
        let baseSets: Int
        switch experience {
        case .beginner: baseSets = 3
        case .intermediate: baseSets = 4
        case .advanced: baseSets = 5
        }

        switch goal {
        case .muscleGain:
            return (baseSets, "", 75)
        case .endurance:
            return (max(3, baseSets - 1), "12-18", 45)
        case .maxStrength:
            return (baseSets, "3-6", 150)
        case .fatLoss:
            return (max(3, baseSets - 1), "10-15", 45)
        case .generalFitness, .athleticPerformance:
            return (baseSets, "8-14", 60)
        case .beginnerForm:
            return (3, "8-10", 60)
        }
    }

    private func difficulty(for experience: ExperienceLevel, index: Int) -> String {
        switch experience {
        case .beginner:
            return index < 2 ? "Beginner" : "Moderate"
        case .intermediate:
            return index < 4 ? "Intermediate" : "Challenging"
        case .advanced:
            return index < 3 ? "Expert" : "High Intensity"
        }
    }

    private func candidateTemplates(for muscleGroup: MuscleGroup, equipment: Set<Equipment>, count: Int) -> [ExerciseTemplate] {
        let library = exerciseLibrary(for: muscleGroup)
        let matching = library.filter { template in
            template.equipment == .bodyweight || equipment.contains(template.equipment)
        }

        var pool = matching.isEmpty ? exerciseLibrary(for: .fullBody) : matching
        if pool.count < count {
            pool.append(contentsOf: library.filter { !pool.map(\.name).contains($0.name) })
        }

        return Array(pool.prefix(count))
    }

    private func exerciseLibrary(for muscleGroup: MuscleGroup) -> [ExerciseTemplate] {
        switch muscleGroup {
        case .chest:
            return [
                .init(name: "Barbell Bench Press", muscle: .chest, equipment: .barbell, formTip: "Pin shoulder blades down and drive feet into the floor."),
                .init(name: "Incline Dumbbell Press", muscle: .chest, equipment: .dumbbells, formTip: "Lower under control and press slightly back toward the rack."),
                .init(name: "Cable Fly", muscle: .chest, equipment: .cableMachine, formTip: "Keep elbows softly bent and squeeze through the midline."),
                .init(name: "Chest Press Machine", muscle: .chest, equipment: .chestPress, formTip: "Set handles at mid-chest and avoid shrugging."),
                .init(name: "Push-Up", muscle: .chest, equipment: .bodyweight, formTip: "Brace abs and keep ribs stacked over hips.")
            ]
        case .back:
            return [
                .init(name: "Lat Pulldown", muscle: .back, equipment: .latPulldown, formTip: "Pull elbows toward your ribs, not your hands toward your chest."),
                .init(name: "Seated Cable Row", muscle: .back, equipment: .rowMachine, formTip: "Pause with shoulder blades packed back and down."),
                .init(name: "Pull-Up", muscle: .back, equipment: .pullUpBar, formTip: "Start from a dead hang and pull chest toward the bar."),
                .init(name: "Barbell Row", muscle: .back, equipment: .barbell, formTip: "Hinge hard and keep the bar close to your thighs."),
                .init(name: "One-Arm Dumbbell Row", muscle: .back, equipment: .dumbbells, formTip: "Pull elbow toward the hip without twisting.")
            ]
        case .legs:
            return [
                .init(name: "Back Squat", muscle: .legs, equipment: .barbell, formTip: "Brace before each rep and keep pressure through mid-foot."),
                .init(name: "Leg Press", muscle: .legs, equipment: .legPress, formTip: "Use a deep range without letting hips roll off the pad."),
                .init(name: "Romanian Deadlift", muscle: .legs, equipment: .barbell, formTip: "Push hips back until hamstrings load, then stand tall."),
                .init(name: "Leg Extension", muscle: .legs, equipment: .legExtension, formTip: "Pause at lockout and lower slowly."),
                .init(name: "Lying Leg Curl", muscle: .legs, equipment: .legCurl, formTip: "Keep hips pinned and curl through the hamstrings."),
                .init(name: "Walking Lunge", muscle: .legs, equipment: .dumbbells, formTip: "Take controlled steps and keep the front knee tracking over toes.")
            ]
        case .shoulders:
            return [
                .init(name: "Overhead Press", muscle: .shoulders, equipment: .barbell, formTip: "Squeeze glutes and press through a stacked torso."),
                .init(name: "Dumbbell Lateral Raise", muscle: .shoulders, equipment: .dumbbells, formTip: "Lead with elbows and stop around shoulder height."),
                .init(name: "Shoulder Press Machine", muscle: .shoulders, equipment: .shoulderPress, formTip: "Keep ribs down and avoid bouncing out of the bottom."),
                .init(name: "Cable Face Pull", muscle: .shoulders, equipment: .cableMachine, formTip: "Pull rope toward eyes with thumbs traveling back."),
                .init(name: "Pike Push-Up", muscle: .shoulders, equipment: .bodyweight, formTip: "Keep hips high and lower crown toward the floor.")
            ]
        case .arms:
            return [
                .init(name: "Barbell Curl", muscle: .arms, equipment: .barbell, formTip: "Lock elbows beside ribs and avoid swinging."),
                .init(name: "Cable Triceps Pressdown", muscle: .arms, equipment: .cableMachine, formTip: "Pin elbows and finish with hard triceps extension."),
                .init(name: "Dumbbell Hammer Curl", muscle: .arms, equipment: .dumbbells, formTip: "Keep wrists neutral and control the lowering phase."),
                .init(name: "Bench Dip", muscle: .arms, equipment: .bench, formTip: "Keep shoulders down and stop if the front shoulder pinches."),
                .init(name: "Close-Grip Push-Up", muscle: .arms, equipment: .bodyweight, formTip: "Keep elbows tucked and move as one rigid plank.")
            ]
        case .core:
            return [
                .init(name: "Plank", muscle: .core, equipment: .bodyweight, formTip: "Tuck pelvis slightly and breathe behind the brace."),
                .init(name: "Cable Crunch", muscle: .core, equipment: .cableMachine, formTip: "Round through the abs instead of pulling with arms."),
                .init(name: "Hanging Knee Raise", muscle: .core, equipment: .pullUpBar, formTip: "Posteriorly tilt pelvis at the top of each rep."),
                .init(name: "Dead Bug", muscle: .core, equipment: .bodyweight, formTip: "Keep low back heavy against the floor."),
                .init(name: "Weighted Sit-Up", muscle: .core, equipment: .dumbbells, formTip: "Move slowly and keep tension through the abs.")
            ]
        case .fullBody:
            return [
                .init(name: "Goblet Squat", muscle: .legs, equipment: .dumbbells, formTip: "Hold the bell high and sit between your hips."),
                .init(name: "Dumbbell Bench Press", muscle: .chest, equipment: .dumbbells, formTip: "Let elbows travel at roughly 45 degrees from your torso."),
                .init(name: "Lat Pulldown", muscle: .back, equipment: .latPulldown, formTip: "Drive elbows down and keep chest tall."),
                .init(name: "Romanian Deadlift", muscle: .legs, equipment: .barbell, formTip: "Keep lats tight and push hips straight back."),
                .init(name: "Dumbbell Lateral Raise", muscle: .shoulders, equipment: .dumbbells, formTip: "Raise with control and avoid traps taking over."),
                .init(name: "Cable Triceps Pressdown", muscle: .arms, equipment: .cableMachine, formTip: "Finish each rep by spreading the rope apart."),
                .init(name: "Plank", muscle: .core, equipment: .bodyweight, formTip: "Own a straight line from ears to ankles."),
                .init(name: "Treadmill Incline Walk", muscle: .fullBody, equipment: .treadmill, formTip: "Stay tall, keep cadence smooth, and breathe nasally if possible.")
            ]
        }
    }
}
