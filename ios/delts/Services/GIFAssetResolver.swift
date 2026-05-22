import Foundation

struct GIFAssetResolver {
    static func assetName(for muscleGroup: MuscleGroup) -> String {
        switch muscleGroup {
        case .chest: return "chest"
        case .back: return "back"
        case .legs: return "legs"
        case .shoulders: return "shoulders"
        case .arms: return "arms"
        case .core: return "core"
        case .fullBody: return "fullbody"
        }
    }

    static func url(for muscleGroup: MuscleGroup) -> URL? {
        Bundle.main.url(forResource: assetName(for: muscleGroup), withExtension: "gif")
    }
}

