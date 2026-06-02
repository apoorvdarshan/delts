import ActivityKit
import SwiftUI
import WidgetKit

private let liveActivityAccent = Color(red: 0.72, green: 1.0, blue: 0.18)
private let liveActivityBackground = Color(red: 0.02, green: 0.03, blue: 0.025)

struct WorkoutTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutTimerActivityAttributes.self) { context in
            WorkoutTimerLockScreenView(state: context.state)
                .activityBackgroundTint(liveActivityBackground)
                .activitySystemActionForegroundColor(liveActivityAccent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 7) {
                        DeltsLiveActivityLogo(size: 26, cornerRadius: 7)
                        Text("Delts")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TimerText(startedAt: context.state.startedAt, size: 18)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityStatsRow(state: context.state)
                }
            } compactLeading: {
                DeltsLiveActivityLogo(size: 22, cornerRadius: 6)
            } compactTrailing: {
                Text(context.state.startedAt, style: .timer)
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            } minimal: {
                DeltsLiveActivityLogo(size: 20, cornerRadius: 5)
            }
        }
    }
}

private struct WorkoutTimerLockScreenView: View {
    let state: WorkoutTimerActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 8) {
                DeltsLiveActivityLogo(size: 34, cornerRadius: 8)

                Text("DELTS")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(liveActivityAccent)

                Text(state.dayTitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.64))
                    .lineLimit(1)

                Spacer()
            }

            HStack(alignment: .center, spacing: 9) {
                Image(systemName: "timer")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(liveActivityAccent)

                TimerText(startedAt: state.startedAt, size: 52)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LiveActivityStatsRow(state: state)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct LiveActivityStatsRow: View {
    let state: WorkoutTimerActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 8) {
            stat("Sets", value: "\(state.setCount)")
            stat(state.workoutCount == 1 ? "Workout" : "Workouts", value: "\(state.workoutCount)")
            stat("Reps", value: "\(state.repCount)")
        }
    }

    private func stat(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(liveActivityAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.66))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.07), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.09), lineWidth: 0.8)
        }
    }
}

private struct DeltsLiveActivityLogo: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        Image("DeltsLiveActivityLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(liveActivityAccent.opacity(0.45), lineWidth: 0.7)
            }
            .accessibilityHidden(true)
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
