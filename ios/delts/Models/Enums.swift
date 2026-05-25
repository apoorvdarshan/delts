import Foundation

enum MuscleGroup: String, CaseIterable, Identifiable, Codable, Hashable {
    case chest = "Chest"
    case back = "Back"
    case legs = "Legs"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case core = "Core"
    case fullBody = "Full Body"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.pullup"
        case .legs: return "figure.run"
        case .shoulders: return "figure.strengthtraining.functional"
        case .arms: return "dumbbell.fill"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.highintensity.intervaltraining"
        }
    }
}

enum FitnessGoal: String, CaseIterable, Identifiable, Codable, Hashable {
    case muscleGain = "Muscle Gain"
    case endurance = "Endurance"
    case maxStrength = "Max Strength"
    case fatLoss = "Fat Loss"
    case generalFitness = "General Fitness"
    case athleticPerformance = "Athletic Performance"
    case beginnerForm = "Beginner Form"

    var id: String { rawValue }
    var title: String { rawValue }

    static let profileCases: [FitnessGoal] = [
        .muscleGain,
        .endurance,
        .maxStrength,
        .fatLoss,
        .generalFitness,
        .athleticPerformance
    ]

    static let planCases: [FitnessGoal] = [
        .muscleGain,
        .endurance,
        .maxStrength,
        .fatLoss,
        .beginnerForm
    ]
}

enum ExperienceLevel: String, CaseIterable, Identifiable, Codable, Hashable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
    var title: String { rawValue }
}

enum WorkoutSplit: String, CaseIterable, Identifiable, Codable, Hashable {
    case fullBody = "Full Body"
    case pushPullLegs = "Push Pull Legs"
    case upperLower = "Upper Lower"
    case broSplit = "Bro Split"
    case custom = "Custom"

    var id: String { rawValue }
    var title: String { rawValue }
}

enum BodyFocus: String, CaseIterable, Identifiable, Codable, Hashable {
    case bigArms = "Big Arms"
    case boulderShoulders = "Boulder Shoulders"
    case massiveChest = "Massive Chest"
    case sixPackAbs = "Six Pack Abs"
    case wideBack = "Wide Back"
    case strongLegs = "Strong Legs"
    case biggerGlutes = "Bigger Glutes"
    case fullBodyAesthetic = "Full Body Aesthetic"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .bigArms: return "dumbbell.fill"
        case .boulderShoulders: return "figure.strengthtraining.functional"
        case .massiveChest: return "figure.strengthtraining.traditional"
        case .sixPackAbs: return "figure.core.training"
        case .wideBack: return "figure.pullup"
        case .strongLegs: return "figure.run"
        case .biggerGlutes: return "figure.lower.body.flexibility"
        case .fullBodyAesthetic: return "figure.highintensity.intervaltraining"
        }
    }
}

enum FitnessIssue: String, CaseIterable, Identifiable, Codable, Hashable {
    case noConsistency = "No consistency"
    case unknownTraining = "Don't know what to train"
    case plateau = "Plateau"
    case weakForm = "Weak form"
    case lowMotivation = "Low motivation"
    case crowdedGym = "Too crowded gym"
    case injuryPain = "Injury/pain"
    case notEnoughTime = "Not enough time"
    case other = "Other"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .noConsistency: return "calendar.badge.exclamationmark"
        case .unknownTraining: return "questionmark"
        case .plateau: return "chart.line.flattrend.xyaxis"
        case .weakForm: return "exclamationmark.triangle"
        case .lowMotivation: return "bolt.slash"
        case .crowdedGym: return "person.3"
        case .injuryPain: return "cross.case"
        case .notEnoughTime: return "clock"
        case .other: return "text.bubble"
        }
    }
}

enum Equipment: String, CaseIterable, Identifiable, Codable, Hashable {
    case dumbbells = "Dumbbells"
    case barbell = "Barbell"
    case cableMachine = "Cable Machine"
    case smithMachine = "Smith Machine"
    case bench = "Bench"
    case chestPress = "Chest Press"
    case shoulderPress = "Shoulder Press"
    case latPulldown = "Lat Pulldown"
    case rowMachine = "Row Machine"
    case legPress = "Leg Press"
    case legExtension = "Leg Extension"
    case legCurl = "Leg Curl"
    case pullUpBar = "Pull-up Bar"
    case treadmill = "Treadmill"
    case bodyweight = "Bodyweight"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .dumbbells: return "dumbbell.fill"
        case .barbell: return "scalemass.fill"
        case .cableMachine: return "point.3.connected.trianglepath.dotted"
        case .smithMachine: return "rectangle.connected.to.line.below"
        case .bench: return "rectangle.and.hand.point.up.left"
        case .chestPress: return "figure.strengthtraining.traditional"
        case .shoulderPress: return "figure.strengthtraining.functional"
        case .latPulldown: return "figure.pullup"
        case .rowMachine: return "figure.rower"
        case .legPress: return "figure.run"
        case .legExtension: return "figure.kickboxing"
        case .legCurl: return "figure.flexibility"
        case .pullUpBar: return "figure.pullup"
        case .treadmill: return "figure.run.treadmill"
        case .bodyweight: return "figure.cooldown"
        }
    }
}
