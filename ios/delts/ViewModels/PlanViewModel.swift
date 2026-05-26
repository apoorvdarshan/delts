import Combine
import SwiftUI

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var selectedMuscleGroup: MuscleGroup = .chest
    @Published var selectedGoal: FitnessGoal = .muscleGain
    @Published var selectedExperience: ExperienceLevel = .intermediate
    @Published var selectedEquipment: Set<Equipment> = [.dumbbells, .barbell, .bench, .cableMachine, .bodyweight]
    @Published var selectedDuration: Int = 60
    @Published var isGenerating = false
    @Published var statusMessage: String?

    private let localGenerator = LocalWorkoutGenerator()
    private let geminiService = GeminiWorkoutService()

    func generateWorkout(profile: UserProfile?) async -> WorkoutPlan? {
        isGenerating = true
        statusMessage = nil
        defer { isGenerating = false }

        let activeProfile = profile ?? UserProfile.defaultProfile()
        let equipment = selectedEquipment.isEmpty ? activeProfile.availableEquipment : selectedEquipment

        if GeminiConfig.hasAPIKey {
            do {
                return try await geminiService.generateWorkout(
                    profile: activeProfile,
                    muscleGroup: selectedMuscleGroup,
                    goal: selectedGoal,
                    equipment: equipment,
                    duration: selectedDuration
                )
            } catch {
                statusMessage = "AI generation failed. Built an offline plan instead."
            }
        } else {
            statusMessage = "Offline plan generated. Add a Gemini key locally to enable AI."
        }

        return localGenerator.generate(
            profile: activeProfile,
            muscleGroup: selectedMuscleGroup,
            goal: selectedGoal,
            equipment: equipment,
            duration: selectedDuration,
            experience: selectedExperience
        )
    }

    func syncDefaults(from profile: UserProfile?) {
        guard let profile else { return }
        selectedExperience = profile.experienceLevel
        selectedGoal = FitnessGoal.planCases.contains(profile.mainGoal) ? profile.mainGoal : .muscleGain
        selectedDuration = profile.workoutDurationMinutes
        selectedEquipment = profile.availableEquipment
    }
}
