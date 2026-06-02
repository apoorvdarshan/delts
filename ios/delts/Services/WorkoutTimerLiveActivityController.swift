import ActivityKit
import Foundation

@MainActor
final class WorkoutTimerLiveActivityController {
    static let shared = WorkoutTimerLiveActivityController()

    private init() {}

    func start(
        sessionID: String,
        startedAt: Date,
        dayTitle: String,
        setCount: Int,
        workoutCount: Int,
        repCount: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        Task {
            await end()

            let attributes = WorkoutTimerActivityAttributes(sessionID: sessionID)
            let state = WorkoutTimerActivityAttributes.ContentState(
                startedAt: startedAt,
                dayTitle: dayTitle,
                setCount: setCount,
                workoutCount: workoutCount,
                repCount: repCount
            )

            do {
                _ = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
            } catch {
                #if DEBUG
                print("Unable to start workout timer Live Activity: \(error)")
                #endif
            }
        }
    }

    func update(
        sessionID: String,
        startedAt: Date,
        dayTitle: String,
        setCount: Int,
        workoutCount: Int,
        repCount: Int
    ) {
        Task {
            let state = WorkoutTimerActivityAttributes.ContentState(
                startedAt: startedAt,
                dayTitle: dayTitle,
                setCount: setCount,
                workoutCount: workoutCount,
                repCount: repCount
            )
            for activity in Activity<WorkoutTimerActivityAttributes>.activities where activity.attributes.sessionID == sessionID {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        }
    }

    func end() async {
        for activity in Activity<WorkoutTimerActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
