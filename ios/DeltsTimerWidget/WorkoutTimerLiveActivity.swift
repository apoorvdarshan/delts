import ActivityKit
import SwiftUI
import WidgetKit

struct WorkoutTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutTimerActivityAttributes.self) { context in
            WorkoutTimerLockScreenView(state: context.state)
                .activityBackgroundTint(Color(red: 0.02, green: 0.03, blue: 0.025))
                .activitySystemActionForegroundColor(Color(red: 0.72, green: 1.0, blue: 0.18))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Delts", systemImage: "timer")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(startedAt: context.state.startedAt, size: 18)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityStatsRow(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundStyle(Color(red: 0.72, green: 1.0, blue: 0.18))
            } compactTrailing: {
                Text(context.state.startedAt, style: .timer)
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundStyle(Color(red: 0.72, green: 1.0, blue: 0.18))
            }
        }
    }
}

private struct WorkoutTimerLockScreenView: View {
    let state: WorkoutTimerActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DELTS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.72, green: 1.0, blue: 0.18))
                    Text(state.dayTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.88))
                }

                Spacer()

                TimerText(startedAt: state.startedAt, size: 32)
            }

            LiveActivityStatsRow(state: state)
        }
        .padding(18)
    }
}

private struct LiveActivityStatsRow: View {
    let state: WorkoutTimerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 10) {
            stat("Sets", value: "\(state.setCount)")
            stat("Workouts", value: "\(state.workoutCount)")
            stat("Reps", value: "\(state.repCount)")
            stat("Burn", value: "-- kcal")
        }
    }

    private func stat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.72, green: 1.0, blue: 0.18))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.66))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TimerText: View {
    let startedAt: Date
    let size: CGFloat

    var body: some View {
        Text(startedAt, style: .timer)
            .font(.system(size: size, weight: .black, design: .rounded).monospacedDigit())
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
