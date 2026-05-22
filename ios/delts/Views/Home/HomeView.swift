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
                    header
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
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        DeltsHeader(
            eyebrow: "delts",
            title: "Hey, \(displayName)",
            subtitle: "Ready to crush your goals today?",
            trailingSystemImage: "bell"
        )
    }

    private var todayWorkout: some View {
        GlassCard(padding: 0, cornerRadius: 24) {
            ZStack(alignment: .bottomLeading) {
                AnimatedExerciseVisual(muscleGroup: recommendedMuscle, height: 214)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.88),
                                Color.black.opacity(0.34),
                                Color.black.opacity(0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.02),
                                Color.black.opacity(0.76)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Today's Focus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.72))
                        Text(recommendedTitle)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                        Text("\(recommendedExerciseCount) exercises - \(profile?.workoutDurationMinutes ?? 60) min")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    NavigationLink {
                        PlanBuilderView()
                    } label: {
                        HStack {
                            Text("Start Workout")
                            Spacer()
                            Image(systemName: "play.fill")
                        }
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: 220)
                        .frame(height: 46)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(
                                colors: [.deltsElectricBlue, .deltsInferno],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var glanceStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeltsSectionHeader(title: "At a Glance")

            HStack(spacing: 10) {
                DeltsMetricTile(
                    title: "Goal",
                    value: profile?.mainGoal.shortTitle ?? "Muscle",
                    systemImage: "flame.fill",
                    tint: .deltsInferno
                )
                DeltsMetricTile(
                    title: "Weekly",
                    value: "\(profile?.workoutFrequencyPerWeek ?? 4)x",
                    systemImage: "calendar",
                    tint: .deltsAcidGreen
                )
                DeltsMetricTile(
                    title: "History",
                    value: "\(completedWorkouts.count)",
                    systemImage: "checkmark.seal.fill",
                    tint: .deltsElectricBlue
                )
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeltsSectionHeader(title: "Quick Actions")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                NavigationLink {
                    PlanBuilderView()
                } label: {
                    DeltsActionTile(title: "Build Plan", systemImage: "sparkles", tint: .deltsElectricBlue)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EquipmentScanComingSoonView()
                } label: {
                    DeltsActionTile(title: "Scan", systemImage: "camera.viewfinder", tint: .deltsInferno)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EquipmentManualSelectionView()
                } label: {
                    DeltsActionTile(title: "Gear", systemImage: "dumbbell.fill", tint: .deltsAcidGreen)
                }
                .buttonStyle(.plain)

                if let latest = completedWorkouts.first {
                    NavigationLink {
                        CompletedWorkoutDetailView(workout: latest)
                    } label: {
                        DeltsActionTile(title: "History", systemImage: "clock.arrow.circlepath", tint: .deltsGold)
                    }
                    .buttonStyle(.plain)
                } else {
                    DeltsActionTile(title: "History", systemImage: "clock.arrow.circlepath", tint: .white.opacity(0.5))
                        .opacity(0.58)
                }
            }
        }
    }

    private var focusSummary: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Current focus")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text(profile?.experienceLevel.title ?? "Intermediate")
                        .font(.caption.weight(.bold))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.08), in: Capsule())
                }
                .foregroundStyle(.white)

                Text(focusText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    MetricPill(title: "Split", value: profile?.workoutSplit.title ?? "PPL", systemImage: "calendar")
                    MetricPill(title: "Duration", value: "\(profile?.workoutDurationMinutes ?? 60)m", systemImage: "timer", tint: .deltsInferno)
                }
            }
        }
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
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.deltsInferno)
                                    .frame(width: 36, height: 36)
                                    .background(Color.deltsInferno.opacity(0.14), in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(workout.title)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text("\(workout.exerciseLogs.count) exercises")
                                        .font(.caption)
                                        .foregroundStyle(Color.deltsMutedText)
                                }

                                Spacer()
                                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.deltsMutedText)
                            }
                            .padding(13)
                            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
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
