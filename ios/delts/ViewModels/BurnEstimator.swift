import Combine
import Foundation
import SwiftData

/// Shared, app-wide calorie-burn estimator. Tracks which completed workouts have
/// an estimate in flight (so Home and Progress > History both show a "calculating"
/// state for the same session), and can compute a missing estimate on demand so
/// the History tab self-heals any workout that didn't get a burn yet.
@MainActor
final class BurnEstimator: ObservableObject {
    static let shared = BurnEstimator()

    @Published private(set) var estimatingIDs: Set<UUID> = []

    private let service = CalorieEstimateService()

    private init() {}

    func isEstimating(_ id: UUID) -> Bool {
        estimatingIDs.contains(id)
    }

    func begin(_ id: UUID) {
        estimatingIDs.insert(id)
    }

    func end(_ id: UUID) {
        estimatingIDs.remove(id)
    }

    /// Estimates calories for a completed workout if it doesn't have one yet and
    /// isn't already being estimated. Persists the result onto the workout and,
    /// when enabled, mirrors it to Apple Health.
    func estimateIfNeeded(
        workout: CompletedWorkout,
        bio: CalorieEstimateService.Bio,
        modelContext: ModelContext,
        appleHealthEnabled: Bool,
        healthKit: HealthKitProgressService
    ) {
        let id = workout.id
        guard GeminiConfig.isAIEnabled,
              PremiumStore.shared.isSubscribed,
              workout.caloriesBurned == nil,
              !estimatingIDs.contains(id) else { return }

        let logs = workout.exerciseLogs
        guard !logs.isEmpty else { return }

        let duration = workout.durationMinutes
        let start = workout.date.addingTimeInterval(-Double(duration * 60))
        let end = workout.date
        let service = self.service

        estimatingIDs.insert(id)
        Task { @MainActor in
            var kcal: Int?
            for attempt in 0..<3 {
                do {
                    kcal = try await service.estimate(durationMinutes: duration, exerciseLogs: logs, bio: bio)
                    break
                } catch {
                    if attempt < 2 { try? await Task.sleep(nanoseconds: 1_500_000_000) }
                }
            }

            if let kcal {
                workout.caloriesBurned = kcal
                try? modelContext.save()
                if appleHealthEnabled {
                    try? await healthKit.requestAccess()
                    try? await healthKit.saveWorkout(id: id, start: start, end: end, calories: kcal)
                }
            }

            estimatingIDs.remove(id)
        }
    }
}
