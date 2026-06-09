import Foundation

/// Builds the system-instruction context the Coach sees on every turn, assembled
/// from everything the app knows: profile/bio, settings, body progress, and
/// completed workout history. Sent server-side via the Gemini proxy.
enum CoachContextBuilder {
    @MainActor
    static func build(
        profile: UserProfile?,
        workouts: [CompletedWorkout],
        snapshots: [ProgressMetricSnapshot]
    ) -> String {
        [
            persona,
            profileSection(profile),
            settingsSection(),
            progressSection(snapshots),
            workoutsSection(workouts)
        ].joined(separator: "\n\n")
    }

    private static let persona = """
    You are Delts Coach, the built-in AI fitness assistant inside the Delts iPhone app.
    You help with training, exercise technique, programming, recovery, nutrition basics, and motivation.
    You can see the user's profile, app settings, body progress, and workout history below — use this \
    data to give specific, personal answers and reference it when it helps.
    Be concise and practical: short paragraphs and tight bullet lists, no filler or boilerplate disclaimers.
    You are not a doctor; for pain, injury, or medical issues, briefly suggest seeing a professional.
    If the user attaches a photo (gym equipment, a meal, a physique, an exercise), analyze it in context.
    Respect the user's units. If data is missing, say so in a few words and give best-effort guidance anyway.
    """

    // MARK: - Profile

    @MainActor
    private static func profileSection(_ profile: UserProfile?) -> String {
        guard let profile else {
            return "PROFILE / BIO: not set up yet."
        }

        let defaults = UserDefaults.standard
        let lb = profile.currentWeightKG * 2.2046226218
        var lines = ["PROFILE / BIO:"]
        lines.append("- Name: \(profile.name)")
        lines.append("- Gender: \(profile.gender), Age: \(profile.age)")
        lines.append("- Height: \(Int(profile.heightCM.rounded())) cm")
        lines.append(String(format: "- Weight: %.1f kg (%.0f lb)", profile.currentWeightKG, lb))
        lines.append(String(format: "- Body fat: %.0f%% now, goal %.0f%%",
                            profile.currentBodyFatPercentage, profile.desiredBodyFatPercentage))
        lines.append("- Experience: \(profile.experienceLevel.title)")
        lines.append("- Main goal: \(profile.mainGoal.title)")

        if let goals = defaults.string(forKey: "profile_selected_goals")?
            .split(separator: "|").map(String.init).joined(separator: ", "), !goals.isEmpty {
            lines.append("- Selected goals: \(goals)")
        }

        let focus = profile.selectedBodyFocus.map(\.title).sorted().joined(separator: ", ")
        if !focus.isEmpty {
            lines.append("- Body focus: \(focus)")
        }

        lines.append("- Weekly frequency: \(profile.workoutFrequencyPerWeek) days")

        let customSplit = defaults.string(forKey: "profile_custom_workout_split")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if profile.workoutSplit == .custom, !customSplit.isEmpty {
            lines.append("- Split: \(profile.workoutSplit.title) (\(customSplit))")
        } else {
            lines.append("- Split: \(profile.workoutSplit.title)")
        }

        lines.append("- Typical session: \(profile.workoutDurationMinutes) min")

        let equipment = profile.availableEquipment.map(\.title).sorted().joined(separator: ", ")
        lines.append("- Equipment: \(equipment.isEmpty ? "Bodyweight only" : equipment)")

        var oneRMs: [String] = []
        if profile.benchPressOneRM > 0 { oneRMs.append("Bench \(number(profile.benchPressOneRM)) kg") }
        if profile.squatOneRM > 0 { oneRMs.append("Squat \(number(profile.squatOneRM)) kg") }
        if profile.deadliftOneRM > 0 { oneRMs.append("Deadlift \(number(profile.deadliftOneRM)) kg") }
        if profile.overheadPressOneRM > 0 { oneRMs.append("OHP \(number(profile.overheadPressOneRM)) kg") }
        if !oneRMs.isEmpty {
            lines.append("- 1RM anchors: \(oneRMs.joined(separator: ", "))")
        }

        var issues = profile.fitnessIssues.map(\.title).sorted()
        let extraIssues = defaults.string(forKey: "profile_extra_issues")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if profile.fitnessIssues.contains(.other), !extraIssues.isEmpty {
            issues.removeAll { $0 == FitnessIssue.other.title }
            issues.append("Other: \(extraIssues)")
        }
        if !issues.isEmpty {
            lines.append("- Challenges: \(issues.joined(separator: ", "))")
        }

        let extraGoals = profile.extraGoals.trimmingCharacters(in: .whitespacesAndNewlines)
        if !extraGoals.isEmpty {
            lines.append("- Notes: \(extraGoals)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Settings

    private static func settingsSection() -> String {
        let defaults = UserDefaults.standard
        var lines = ["APP SETTINGS:"]
        lines.append("- Theme: \((defaults.string(forKey: "delts_theme") ?? "lime").capitalized)")
        lines.append("- Appearance: \((defaults.string(forKey: "app_appearance") ?? "system").capitalized)")

        let weightSystem = defaults.string(forKey: "profile_weight_measurement_system") ?? "metric"
        lines.append("- Weight units: \(weightSystem == "imperial" ? "lb (imperial)" : "kg (metric)")")

        let heightSystem = defaults.string(forKey: "profile_height_measurement_system") ?? "metric"
        lines.append("- Height units: \(heightSystem == "imperial" ? "ft/in (imperial)" : "cm (metric)")")

        let goalWeight = defaults.double(forKey: "profile_goal_weight_kg")
        if goalWeight > 0 {
            lines.append(String(format: "- Goal weight: %.1f kg", goalWeight))
        }

        if let rpe = defaults.string(forKey: "profile_rpe_scale")?
            .trimmingCharacters(in: .whitespacesAndNewlines), !rpe.isEmpty {
            lines.append("- RPE scale: \(rpe)")
        }

        lines.append("- Apple Health sync: \(defaults.bool(forKey: "apple_health_enabled") ? "on" : "off")")
        return lines.joined(separator: "\n")
    }

    // MARK: - Progress

    private static func progressSection(_ snapshots: [ProgressMetricSnapshot]) -> String {
        guard !snapshots.isEmpty else {
            return "BODY PROGRESS: no weight or body-fat logs yet."
        }

        let sorted = snapshots.sorted { $0.date < $1.date }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var lines = ["BODY PROGRESS (oldest to newest):"]

        let weights = sorted.compactMap { $0.weightKg }
        if let first = weights.first, let last = weights.last {
            lines.append(String(format: "- Weight: %.1f kg latest (%+.1f kg across %d logs)",
                                last, last - first, weights.count))
        }

        let bodyFats = sorted.compactMap { $0.bodyFat }
        if let first = bodyFats.first, let last = bodyFats.last {
            lines.append(String(format: "- Body fat: %.1f%% latest (%+.1f%% across %d logs)",
                                last, last - first, bodyFats.count))
        }

        lines.append("Recent logs:")
        for snapshot in sorted.suffix(40) {
            var parts = [formatter.string(from: snapshot.date)]
            if let weight = snapshot.weightKg { parts.append(String(format: "%.1f kg", weight)) }
            if let bodyFat = snapshot.bodyFat { parts.append(String(format: "%.1f%% bf", bodyFat)) }
            lines.append("  • " + parts.joined(separator: ", "))
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Workouts

    private static func workoutsSection(_ workouts: [CompletedWorkout]) -> String {
        guard !workouts.isEmpty else {
            return "WORKOUT HISTORY: no completed workouts logged yet."
        }

        let sorted = workouts.sorted { $0.date > $1.date }
        let recent = Array(sorted.prefix(15))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var lines = ["WORKOUT HISTORY (\(workouts.count) total, most recent first):"]
        for workout in recent {
            lines.append("• \(formatter.string(from: workout.date)) — \(workout.title) (\(workout.durationMinutes) min)")
            for exercise in workout.exerciseLogs {
                let setText = exercise.sets
                    .filter { $0.completed }
                    .map { set -> String in
                        var summary = set.weight.trimmingCharacters(in: .whitespaces)
                        let reps = set.reps.trimmingCharacters(in: .whitespaces)
                        if !reps.isEmpty {
                            summary += summary.isEmpty ? "\(reps) reps" : "×\(reps)"
                        }
                        if let rpe = set.rpe?.trimmingCharacters(in: .whitespaces), !rpe.isEmpty {
                            summary += " @RPE \(rpe)"
                        }
                        return summary.isEmpty ? "done" : summary
                    }
                    .joined(separator: ", ")
                lines.append(setText.isEmpty ? "    - \(exercise.name)" : "    - \(exercise.name): \(setText)")
            }
        }

        if workouts.count > recent.count {
            lines.append("(\(workouts.count - recent.count) older workouts not shown)")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
