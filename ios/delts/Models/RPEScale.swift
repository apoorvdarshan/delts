import Foundation

enum RPEScale: String, CaseIterable, Hashable {
    case strength
    case cr10
    case borg

    static let storageKey = "profile_rpe_scale"

    var title: String {
        switch self {
        case .strength: return "Strength 1-10"
        case .cr10: return "CR10 0-10"
        case .borg: return "Borg 6-20"
        }
    }

    var inputPlaceholder: String {
        switch self {
        case .strength: return "1-10"
        case .cr10: return "0-10"
        case .borg: return "6-20"
        }
    }
}
