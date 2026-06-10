import Combine
import SwiftUI

struct WorkoutDurationRangeOption: Hashable, Identifiable {
    let lowerBound: Int
    let upperBound: Int?

    var id: String {
        if let upperBound {
            return "\(lowerBound)-\(upperBound)"
        }
        return "\(lowerBound)-plus"
    }

    var title: String {
        if let upperBound {
            if lowerBound < 60, upperBound < 60 {
                return String(localized: "\(lowerBound)-\(upperBound) min")
            }
            if lowerBound >= 60, upperBound >= 60 {
                return String(localized: "\(hourText(for: lowerBound))-\(hourText(for: upperBound)) hr")
            }
            return String(localized: "\(durationText(for: lowerBound))-\(durationText(for: upperBound))")
        }
        return String(localized: "\(durationText(for: lowerBound))+")
    }

    var promptText: String {
        if let upperBound {
            return "\(durationText(for: lowerBound)) to \(durationText(for: upperBound))"
        }
        return "\(durationText(for: lowerBound)) or longer"
    }

    var targetMinutes: Int { upperBound ?? 150 }

    static let options: [WorkoutDurationRangeOption] = [
        WorkoutDurationRangeOption(lowerBound: 20, upperBound: 30),
        WorkoutDurationRangeOption(lowerBound: 30, upperBound: 45),
        WorkoutDurationRangeOption(lowerBound: 45, upperBound: 60),
        WorkoutDurationRangeOption(lowerBound: 60, upperBound: 90),
        WorkoutDurationRangeOption(lowerBound: 90, upperBound: 120),
        WorkoutDurationRangeOption(lowerBound: 120, upperBound: nil)
    ]

    static func matching(minutes: Int) -> WorkoutDurationRangeOption {
        options.first { option in
            if let upperBound = option.upperBound {
                return option.lowerBound <= minutes && minutes <= upperBound
            }
            return minutes >= option.lowerBound
        }
            ?? options.min { abs($0.targetMinutes - minutes) < abs($1.targetMinutes - minutes) }
            ?? options[2]
    }

    private func durationText(for minutes: Int) -> String {
        switch minutes {
        case 120:
            return String(localized: "2 hr")
        case let value where value > 60 && value % 60 == 30:
            return "\(Double(value) / 60.0) hr"
        case let value where value >= 60 && value % 60 == 0:
            return String(localized: "\(value / 60) hr")
        default:
            return String(localized: "\(minutes) min")
        }
    }

    private func hourText(for minutes: Int) -> String {
        let hours = Double(minutes) / 60.0
        if hours.rounded() == hours {
            return "\(Int(hours))"
        }
        return hours.formatted(.number.precision(.fractionLength(1)))
    }
}

@MainActor
final class PlanViewModel: ObservableObject {
    @Published var selectedMuscleGroup: MuscleGroup = .chest
    @Published var selectedGoal: FitnessGoal = .muscleGain
    @Published var selectedExperience: ExperienceLevel = .intermediate
    @Published var selectedEquipment: Set<Equipment> = [.dumbbells, .barbell, .bench, .cableMachine, .bodyweight]
    @Published var selectedDurationRange: WorkoutDurationRangeOption = WorkoutDurationRangeOption.options[2]
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

        let isPremium = await MainActor.run { PremiumStore.shared.isSubscribed }
        if GeminiConfig.isAIEnabled && isPremium {
            do {
                return try await geminiService.generateWorkout(
                    profile: activeProfile,
                    muscleGroup: selectedMuscleGroup,
                    goal: selectedGoal,
                    equipment: equipment,
                    durationRange: selectedDurationRange
                )
            } catch {
                statusMessage = "AI generation failed. Built an offline plan instead."
            }
        } else {
            statusMessage = String(localized: "Offline plan generated from your profile.")
        }

        return localGenerator.generate(
            profile: activeProfile,
            muscleGroup: selectedMuscleGroup,
            goal: selectedGoal,
            equipment: equipment,
            durationRange: selectedDurationRange,
            experience: selectedExperience
        )
    }

    func syncDefaults(from profile: UserProfile?) {
        guard let profile else { return }
        selectedExperience = profile.experienceLevel
        selectedGoal = FitnessGoal.planCases.contains(profile.mainGoal) ? profile.mainGoal : .muscleGain
        selectedDurationRange = WorkoutDurationRangeOption.matching(minutes: profile.workoutDurationMinutes)
        selectedEquipment = profile.availableEquipment
    }
}
