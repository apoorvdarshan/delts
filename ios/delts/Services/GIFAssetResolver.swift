import Foundation

struct GIFAssetResolver {
    nonisolated static func resourceName(assetName: String? = nil, exerciseName: String? = nil, muscleGroup: MuscleGroup) -> String? {
        let candidates = [
            assetName,
            exerciseName.map(slug),
            Self.assetName(for: muscleGroup)
        ].compactMap { $0 }

        return candidates.first { candidate in
            Bundle.main.url(forResource: candidate, withExtension: "gif") != nil
        }
    }

    nonisolated static func assetName(for muscleGroup: MuscleGroup) -> String {
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

    nonisolated static func url(for muscleGroup: MuscleGroup) -> URL? {
        Bundle.main.url(forResource: assetName(for: muscleGroup), withExtension: "gif")
    }

    nonisolated private static func slug(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}
