import Foundation

/// Estimates calories burned for a finished session by sending the workout
/// (duration + exercises/sets/reps/RPE) and the person's bio data to Gemini
/// through the delts.fit proxy.
struct CalorieEstimateService {
    struct Bio {
        let gender: String
        let age: Int
        let heightCM: Double
        let weightKG: Double
        let bodyFatPercentage: Double
        let experience: String
    }

    enum EstimateError: Error {
        case notConfigured
        case network
        case server(Int)
        case parse
    }

    func estimate(durationMinutes: Int, exercises: [PlannedRoutineExercise], bio: Bio) async throws -> Int {
        guard let url = GeminiConfig.proxyURL else { throw EstimateError.notConfigured }

        let payload: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": Self.prompt(durationMinutes: durationMinutes, exercises: exercises, bio: bio)]]]],
            "generationConfig": ["temperature": 0.2, "responseMimeType": "application/json"]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw EstimateError.network
        }

        guard let http = response as? HTTPURLResponse else { throw EstimateError.network }
        guard (200..<300).contains(http.statusCode) else { throw EstimateError.server(http.statusCode) }

        let decoded = try JSONDecoder().decode(GeminiTextResponse.self, from: data)
        let text = decoded.candidates?.first?.content?.parts?.compactMap { $0.text }.joined() ?? ""
        guard let calories = Self.parseCalories(text) else { throw EstimateError.parse }
        return calories
    }

    private static func parseCalories(_ text: String) -> Int? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let data = cleaned.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let value = object["calories"] as? Int { return clamp(value) }
            if let value = object["calories"] as? Double { return clamp(Int(value.rounded())) }
            if let value = object["calories"] as? String,
               let parsed = Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return clamp(parsed)
            }
        }

        // Fallback: first run of digits anywhere in the response.
        let digits = cleaned.prefix { !$0.isNumber }.isEmpty ? cleaned : cleaned
        let firstNumber = digits.drop { !$0.isNumber }.prefix { $0.isNumber }
        if let parsed = Int(firstNumber) { return clamp(parsed) }
        return nil
    }

    private static func clamp(_ value: Int) -> Int { min(max(value, 0), 5000) }

    private static func prompt(durationMinutes: Int, exercises: [PlannedRoutineExercise], bio: Bio) -> String {
        var lines: [String] = []
        for exercise in exercises {
            let reps = exercise.normalizedSetReps
            let rpe = exercise.normalizedSetRPE
            let setCount = max(exercise.sets, 1)
            var setParts: [String] = []
            for index in 0..<setCount {
                let repValue = reps.indices.contains(index) ? reps[index].trimmingCharacters(in: .whitespaces) : ""
                let rpeValue = rpe.indices.contains(index) ? rpe[index].trimmingCharacters(in: .whitespaces) : ""
                var part = repValue.isEmpty ? "?" : "\(repValue) reps"
                if !rpeValue.isEmpty { part += " @RPE \(rpeValue)" }
                setParts.append(part)
            }
            let muscle = exercise.primaryMuscles.first ?? "Unspecified"
            lines.append("- \(exercise.name) (\(muscle), \(exercise.rawEquipment)): \(setParts.joined(separator: ", "))")
        }
        let exerciseText = lines.isEmpty ? "- (no logged sets)" : lines.joined(separator: "\n")

        return """
        Estimate the total calories burned during this resistance-training session.
        Weigh the person's body data, the exercises and their sets/reps/effort, and the total session time.
        Be realistic for weight training (not steady-state cardio). Return STRICT JSON only, no prose:
        {"calories": <integer kcal>}

        Person: \(bio.gender), age \(bio.age), height \(Int(bio.heightCM.rounded())) cm, \
        weight \(String(format: "%.1f", bio.weightKG)) kg, body fat \(Int(bio.bodyFatPercentage.rounded()))%, \
        experience \(bio.experience).
        Session duration: \(durationMinutes) minutes.
        Exercises:
        \(exerciseText)
        """
    }
}

private struct GeminiTextResponse: Decodable {
    let candidates: [Candidate]?
    struct Candidate: Decodable { let content: Content? }
    struct Content: Decodable { let parts: [Part]? }
    struct Part: Decodable { let text: String? }
}

/// Persists the estimated calories burned per workout day (keyed by date key).
enum WorkoutBurnStore {
    private static let key = "delts.workoutBurn.v1"

    static func load() -> [String: Int] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return value
    }

    static func save(_ value: [String: Int]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
