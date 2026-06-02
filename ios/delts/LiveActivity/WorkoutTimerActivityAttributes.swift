import ActivityKit
import Foundation

struct WorkoutTimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var dayTitle: String
        var setCount: Int
        var workoutCount: Int
        var repCount: Int
    }

    var sessionID: String
}
