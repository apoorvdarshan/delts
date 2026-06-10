import Foundation

enum GeminiWorkoutError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidJSON
    case emptyExercises

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Gemini URL could not be created."
        case .invalidResponse: return "Gemini returned an invalid response."
        case .invalidJSON: return "Gemini returned JSON that could not be parsed."
        case .emptyExercises: return "Gemini returned no exercises."
        }
    }
}

final class GeminiWorkoutService {
    func generateWorkout(
        profile: UserProfile,
        muscleGroup: MuscleGroup,
        goal: FitnessGoal,
        equipment: Set<Equipment>,
        durationRange: WorkoutDurationRangeOption
    ) async throws -> WorkoutPlan {
        // Requests go through the delts.fit proxy; the API key lives server-side
        // as a Vercel env var and is never embedded in the app.
        guard let url = GeminiConfig.proxyURL else {
            throw GeminiWorkoutError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(GeminiConfig.deviceID, forHTTPHeaderField: "X-Delts-Device")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(prompt: prompt(
            profile: profile,
            muscleGroup: muscleGroup,
            goal: goal,
            equipment: equipment,
            durationRange: durationRange
        )))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw GeminiWorkoutError.invalidResponse
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates.first?.content.parts.compactMap(\.text).joined(separator: "\n") else {
            throw GeminiWorkoutError.invalidResponse
        }

        return try decodePlan(
            from: text,
            muscleGroup: muscleGroup,
            goal: goal,
            durationRange: durationRange
        )
    }

    private func prompt(
        profile: UserProfile,
        muscleGroup: MuscleGroup,
        goal: FitnessGoal,
        equipment: Set<Equipment>,
        durationRange: WorkoutDurationRangeOption
    ) -> String {
        let equipmentText = equipment.map(\.title).sorted().joined(separator: ", ")
        let exerciseBounds = exerciseCountBounds(for: durationRange.targetMinutes)
        let bodyFocusText = profile.selectedBodyFocus.map(\.title).sorted().joined(separator: ", ")
        let selectedGoalText = UserDefaults.standard.string(forKey: "profile_selected_goals")?
            .split(separator: "|")
            .map(String.init)
            .joined(separator: ", ")
        let goalsText = selectedGoalText?.isEmpty == false ? selectedGoalText ?? profile.mainGoal.title : profile.mainGoal.title
        let extraIssues = UserDefaults.standard.string(forKey: "profile_extra_issues")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var issueTitles = profile.fitnessIssues.map(\.title).sorted()
        if profile.fitnessIssues.contains(.other), !extraIssues.isEmpty {
            issueTitles.removeAll { $0 == FitnessIssue.other.title }
            issueTitles.append("\(FitnessIssue.other.title): \(extraIssues)")
        }
        let issuesText = issueTitles.joined(separator: ", ")
        let customWorkoutSplit = UserDefaults.standard.string(forKey: "profile_custom_workout_split")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let workoutSplitText: String
        if profile.workoutSplit == .custom, !customWorkoutSplit.isEmpty {
            workoutSplitText = "\(profile.workoutSplit.title): \(customWorkoutSplit)"
        } else {
            workoutSplitText = profile.workoutSplit.title
        }

        return """
        You are delts, a premium gym workout planner. Return strict JSON only. No markdown.

        User profile:
        - Name: \(profile.name)
        - Gender: \(profile.gender)
        - Age: \(profile.age)
        - Height cm: \(profile.heightCM)
        - Weight kg: \(profile.currentWeightKG)
        - Current body fat: \(profile.currentBodyFatPercentage)%
        - Desired body fat: \(profile.desiredBodyFatPercentage)%
        - Experience: \(profile.experienceLevel.title)
        - Goals: \(goalsText)
        - Body focus: \(bodyFocusText)
        - Split: \(workoutSplitText)
        - Issues: \(issuesText)
        - Extra goals: \(profile.extraGoals)

        Requested workout:
        - Muscle group: \(muscleGroup.title)
        - Goal: \(goal.title)
        - Duration range: \(durationRange.promptText)
        - Planning target minutes: \(durationRange.targetMinutes)
        - Available equipment: \(equipmentText)

        JSON schema:
        {
          "title": "string",
          "summary": "string",
          "exercises": [
            {
              "name": "string",
              "targetMuscle": "Chest|Back|Legs|Shoulders|Arms|Core|Full Body",
              "equipment": "Dumbbells|Barbell|Cable Machine|Smith Machine|Bench|Chest Press|Shoulder Press|Lat Pulldown|Row Machine|Leg Press|Leg Extension|Leg Curl|Pull-up Bar|Treadmill|Bodyweight",
              "sets": 3,
              "reps": "",
              "restSeconds": 75,
              "formTip": "string",
              "difficulty": "Beginner|Intermediate|Expert|Challenging|High Intensity"
            }
          ]
        }

        Rules:
        - Return \(exerciseBounds.min) to \(exerciseBounds.max) exercises.
        - Use only available equipment or Bodyweight.
        - No unsafe medical claims.
        - Keep form tips concise and practical.
        """
    }

    private func decodePlan(
        from text: String,
        muscleGroup: MuscleGroup,
        goal: FitnessGoal,
        durationRange: WorkoutDurationRangeOption
    ) throws -> WorkoutPlan {
        let cleaned = cleanJSONText(text)
        guard let data = cleaned.data(using: .utf8) else {
            throw GeminiWorkoutError.invalidJSON
        }

        let aiPlan = try JSONDecoder().decode(AIWorkoutPlan.self, from: data)
        let maxExercises = exerciseCountBounds(for: durationRange.targetMinutes).max
        let limitedExercises = Array(aiPlan.exercises.prefix(maxExercises))

        guard !limitedExercises.isEmpty else {
            throw GeminiWorkoutError.emptyExercises
        }

        let exercises = limitedExercises.enumerated().map { index, exercise in
            WorkoutExercise(
                orderIndex: index,
                name: exercise.name,
                targetMuscle: MuscleGroup(rawValue: exercise.targetMuscle) ?? muscleGroup,
                equipment: Equipment(rawValue: exercise.equipment) ?? .bodyweight,
                sets: max(1, min(exercise.sets, 6)),
                reps: exercise.reps,
                restSeconds: max(30, min(exercise.restSeconds, 240)),
                formTip: exercise.formTip,
                difficulty: exercise.difficulty
            )
        }

        return WorkoutPlan(
            title: aiPlan.title,
            summary: aiPlan.summary,
            muscleGroup: muscleGroup,
            goal: goal,
            durationMinutes: durationRange.targetMinutes,
            generatedByAI: true,
            exercises: exercises
        )
    }

    private func exerciseCountBounds(for duration: Int) -> (min: Int, max: Int) {
        switch duration {
        case ..<35:
            return (4, 5)
        case ..<50:
            return (5, 6)
        case ..<75:
            return (6, 8)
        case ..<105:
            return (8, 10)
        default:
            return (10, 12)
        }
    }

    private func cleanJSONText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned.removeFirst("```json".count)
        } else if cleaned.hasPrefix("```") {
            cleaned.removeFirst("```".count)
        }
        if cleaned.hasSuffix("```") {
            cleaned.removeLast("```".count)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct GeminiRequest: Encodable {
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig

    init(prompt: String) {
        self.contents = [GeminiContent(role: "user", parts: [GeminiPart(text: prompt)])]
        self.generationConfig = GeminiGenerationConfig(
            temperature: 0.35,
            responseMimeType: "application/json"
        )
    }
}

private struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String?
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
    let responseMimeType: String
}

private struct GeminiResponse: Decodable {
    let candidates: [GeminiCandidate]
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

private struct AIWorkoutPlan: Decodable {
    let title: String
    let summary: String
    let exercises: [AIWorkoutExercise]
}

private struct AIWorkoutExercise: Decodable {
    let name: String
    let targetMuscle: String
    let equipment: String
    let sets: Int
    let reps: String
    let restSeconds: Int
    let formTip: String
    let difficulty: String
}
