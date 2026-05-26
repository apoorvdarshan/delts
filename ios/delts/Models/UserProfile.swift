import Foundation
import SwiftData

@Model
final class UserProfile: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var gender: String
    var age: Int
    var heightCM: Double
    var currentWeightKG: Double
    var currentBodyFatPercentage: Double
    var desiredBodyFatPercentage: Double
    var experienceLevelRaw: String
    var mainGoalRaw: String
    var bodyFocusRawValues: [String]
    var workoutFrequencyPerWeek: Int
    var workoutSplitRaw: String
    var workoutDurationMinutes: Int
    var availableEquipmentRawValues: [String]
    var benchPressOneRM: Double
    var squatOneRM: Double
    var deadliftOneRM: Double
    var overheadPressOneRM: Double
    var fitnessIssueRawValues: [String]
    var extraGoals: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "Athlete",
        gender: String = "Male",
        age: Int = 28,
        heightCM: Double = 178,
        currentWeightKG: Double = 82,
        currentBodyFatPercentage: Double = 18,
        desiredBodyFatPercentage: Double = 12,
        experienceLevel: ExperienceLevel = .intermediate,
        mainGoal: FitnessGoal = .muscleGain,
        bodyFocus: Set<BodyFocus> = [.boulderShoulders, .bigArms, .fullBodyAesthetic],
        workoutFrequencyPerWeek: Int = 4,
        workoutSplit: WorkoutSplit = .pushPullLegs,
        workoutDurationMinutes: Int = 60,
        availableEquipment: Set<Equipment> = [.dumbbells, .barbell, .bench, .cableMachine, .latPulldown, .legPress, .bodyweight],
        benchPressOneRM: Double = 0,
        squatOneRM: Double = 0,
        deadliftOneRM: Double = 0,
        overheadPressOneRM: Double = 0,
        fitnessIssues: Set<FitnessIssue> = [.noConsistency, .plateau],
        extraGoals: String = ""
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.age = age
        self.heightCM = heightCM
        self.currentWeightKG = currentWeightKG
        self.currentBodyFatPercentage = currentBodyFatPercentage
        self.desiredBodyFatPercentage = desiredBodyFatPercentage
        self.experienceLevelRaw = experienceLevel.rawValue
        self.mainGoalRaw = mainGoal.rawValue
        self.bodyFocusRawValues = bodyFocus.map { $0.rawValue }.sorted()
        self.workoutFrequencyPerWeek = workoutFrequencyPerWeek
        self.workoutSplitRaw = workoutSplit.rawValue
        self.workoutDurationMinutes = workoutDurationMinutes
        self.availableEquipmentRawValues = availableEquipment.map { $0.rawValue }.sorted()
        self.benchPressOneRM = benchPressOneRM
        self.squatOneRM = squatOneRM
        self.deadliftOneRM = deadliftOneRM
        self.overheadPressOneRM = overheadPressOneRM
        self.fitnessIssueRawValues = fitnessIssues.map { $0.rawValue }.sorted()
        self.extraGoals = extraGoals
        self.updatedAt = Date()
    }

    static func defaultProfile() -> UserProfile {
        UserProfile()
    }

    var experienceLevel: ExperienceLevel {
        get {
            if experienceLevelRaw == "Advanced" {
                return .advanced
            }
            return ExperienceLevel(rawValue: experienceLevelRaw) ?? .beginner
        }
        set {
            experienceLevelRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    var mainGoal: FitnessGoal {
        get { FitnessGoal(rawValue: mainGoalRaw) ?? .muscleGain }
        set {
            mainGoalRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    var selectedBodyFocus: Set<BodyFocus> {
        get { Set(bodyFocusRawValues.compactMap(BodyFocus.init(rawValue:))) }
        set {
            bodyFocusRawValues = newValue.map { $0.rawValue }.sorted()
            updatedAt = Date()
        }
    }

    var workoutSplit: WorkoutSplit {
        get { WorkoutSplit(rawValue: workoutSplitRaw) ?? .fullBody }
        set {
            workoutSplitRaw = newValue.rawValue
            updatedAt = Date()
        }
    }

    var availableEquipment: Set<Equipment> {
        get { Set(availableEquipmentRawValues.compactMap(Equipment.init(rawValue:))) }
        set {
            availableEquipmentRawValues = newValue.map { $0.rawValue }.sorted()
            updatedAt = Date()
        }
    }

    var fitnessIssues: Set<FitnessIssue> {
        get { Set(fitnessIssueRawValues.compactMap(FitnessIssue.init(rawValue:))) }
        set {
            fitnessIssueRawValues = newValue.map { $0.rawValue }.sorted()
            updatedAt = Date()
        }
    }
}
