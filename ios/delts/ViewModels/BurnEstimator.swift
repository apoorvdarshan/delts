import Combine
import Foundation

/// Shared, app-wide tracker of which completed workouts currently have a
/// calorie estimate in flight. Lets Home and the Progress > History tab both
/// show a "calculating" state for the same session, even across tab switches.
@MainActor
final class BurnEstimator: ObservableObject {
    static let shared = BurnEstimator()

    @Published private(set) var estimatingIDs: Set<UUID> = []

    private init() {}

    func begin(_ id: UUID) {
        estimatingIDs.insert(id)
    }

    func end(_ id: UUID) {
        estimatingIDs.remove(id)
    }

    func isEstimating(_ id: UUID) -> Bool {
        estimatingIDs.contains(id)
    }
}
