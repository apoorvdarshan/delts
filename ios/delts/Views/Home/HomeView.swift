import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var completedWorkouts: [CompletedWorkout]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    todayWorkout
                    glanceStats
                    quickActions
                    focusSummary
                    recentWorkouts
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)
            }
            .deltsScreen()
            .contentMargins(.bottom, 110, for: .scrollContent)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("delts")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "bell")
                    }
                    .tint(Color.deltsAccent)
                    .accessibilityLabel("Notifications")
                }
            }
        }
    }

    private var todayWorkout: some View {
        ZStack(alignment: .bottomLeading) {
            AnimatedExerciseVisual(muscleGroup: recommendedMuscle, height: 228)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.05), .black.opacity(0.15), .black.opacity(0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Ready, \(displayName)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))
                    Text(recommendedTitle)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                    Text("\(recommendedExerciseCount) exercises - \(profile?.workoutDurationMinutes ?? 60) min")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }

                NavigationLink {
                    PlanBuilderView()
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color.deltsAccent)
            }
            .padding(18)
        }
    }

    private var glanceStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeltsSectionHeader(title: "At a Glance")

            HStack(alignment: .top, spacing: 0) {
                HomeInlineStat(title: "Goal", value: profile?.mainGoal.shortTitle ?? "Muscle")
                Divider().frame(height: 44)
                HomeInlineStat(title: "Weekly", value: "\(profile?.workoutFrequencyPerWeek ?? 4)x")
                Divider().frame(height: 44)
                HomeInlineStat(title: "History", value: "\(completedWorkouts.count)")
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeltsSectionHeader(title: "Quick Actions")

            HStack(spacing: 10) {
                NavigationLink {
                    PlanBuilderView()
                } label: {
                    HomeActionButton(title: "Build", systemImage: "sparkles", tint: .deltsAccent)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EquipmentScanComingSoonView()
                } label: {
                    HomeActionButton(title: "Scan", systemImage: "camera.viewfinder", tint: .deltsInferno)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EquipmentManualSelectionView()
                } label: {
                    HomeActionButton(title: "Gear", systemImage: "dumbbell.fill", tint: .deltsAcidGreen)
                }
                .buttonStyle(.plain)

                if let latest = completedWorkouts.first {
                    NavigationLink {
                        CompletedWorkoutDetailView(workout: latest)
                    } label: {
                        HomeActionButton(title: "History", systemImage: "clock.arrow.circlepath", tint: .deltsGold)
                    }
                    .buttonStyle(.plain)
                } else {
                    HomeActionButton(title: "History", systemImage: "clock.arrow.circlepath", tint: .secondary)
                        .opacity(0.58)
                }
            }
        }
    }

    private var focusSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Current focus")
                    .font(.headline.weight(.bold))
                Spacer()
                Text(profile?.experienceLevel.title ?? "Intermediate")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
            }
            .foregroundStyle(.primary)

            Text(focusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(spacing: 10) {
                LabeledContent("Split", value: profile?.workoutSplit.title ?? "PPL")
                Divider()
                LabeledContent("Duration", value: "\(profile?.workoutDurationMinutes ?? 60)m")
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var recentWorkouts: some View {
        if !completedWorkouts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                DeltsSectionHeader(title: "Recent Workouts")

                VStack(spacing: 10) {
                    ForEach(completedWorkouts.prefix(3)) { workout in
                        NavigationLink {
                            CompletedWorkoutDetailView(workout: workout)
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(workout.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text("\(workout.exerciseLogs.count) exercises")
                                        .font(.caption)
                                        .foregroundStyle(Color.deltsMutedText)
                                }

                                Spacer()
                                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.deltsMutedText)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if workout.id != completedWorkouts.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var recommendedMuscle: MuscleGroup {
        guard let focus = profile?.selectedBodyFocus.first else { return .chest }
        switch focus {
        case .bigArms: return .arms
        case .boulderShoulders: return .shoulders
        case .massiveChest: return .chest
        case .sixPackAbs: return .core
        case .wideBack: return .back
        case .strongLegs, .biggerGlutes: return .legs
        case .fullBodyAesthetic: return .fullBody
        }
    }

    private var recommendedTitle: String {
        "\(recommendedMuscle.title) \(profile?.mainGoal.title ?? "Muscle Gain")"
    }

    private var recommendedExerciseCount: Int {
        switch profile?.workoutDurationMinutes ?? 60 {
        case ...30: return 4
        case ...45: return 5
        case ...60: return 6
        default: return 8
        }
    }

    private var displayName: String {
        guard let name = profile?.name.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return "Athlete"
        }
        return name
    }

    private var focusText: String {
        let focus = profile?.selectedBodyFocus.map(\.title).sorted().joined(separator: ", ")
        guard let focus, !focus.isEmpty else {
            return "Set body focus and equipment in Profile to sharpen workout recommendations."
        }
        return "\(profile?.mainGoal.title ?? "Muscle Gain") with emphasis on \(focus)."
    }

}

private struct HomeInlineStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
        .padding(.horizontal, 12)
    }
}

private struct HomeActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .contentShape(Rectangle())
    }
}

private extension FitnessGoal {
    var shortTitle: String {
        switch self {
        case .muscleGain: return "Muscle"
        case .endurance: return "Endure"
        case .maxStrength: return "Power"
        case .fatLoss: return "Lean"
        case .generalFitness: return "Fit"
        case .athleticPerformance: return "Sport"
        case .beginnerForm: return "Form"
        }
    }
}
