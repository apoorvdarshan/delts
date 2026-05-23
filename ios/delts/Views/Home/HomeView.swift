import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Query(sort: \CompletedWorkout.date, order: .reverse) private var completedWorkouts: [CompletedWorkout]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: expandedLayout ? 26 : 22) {
                        todayWorkout
                        glanceStats
                        quickActions
                        focusSummary
                        recentWorkouts
                    }
                    .frame(width: max(proxy.size.width - horizontalPadding * 2, 0), alignment: .leading)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
                }
                .deltsScreen()
                .contentMargins(.bottom, 110, for: .scrollContent)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("delts")
                        .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                    } label: {
                        Image(systemName: "bell")
                            .font(.body.weight(.semibold))
                    }
                    .tint(Color.deltsAccent)
                    .accessibilityLabel("Notifications")
                }
            }
        }
    }

    private var todayWorkout: some View {
        ZStack(alignment: .bottomLeading) {
            AnimatedExerciseVisual(muscleGroup: recommendedMuscle, height: heroHeight)
                .saturation(0.92)
                .brightness(-0.04)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.06), location: 0.0),
                            .init(color: .black.opacity(0.18), location: 0.44),
                            .init(color: .black.opacity(0.82), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.16), lineWidth: 0.5)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: expandedLayout ? 18 : 16) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Ready, \(displayName)")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(2)

                        Text(recommendedTitle)
                            .font(.system(expandedLayout ? .title : .largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(expandedLayout ? 3 : 2)
                            .minimumScaleFactor(0.78)

                        Text("\(recommendedExerciseCount) exercises - \(profile?.workoutDurationMinutes ?? 60) min")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: recommendedMuscle.icon)
                        .font(.system(size: expandedLayout ? 22 : 24, weight: .semibold))
                        .foregroundStyle(Color.deltsOnAccent)
                        .frame(width: expandedLayout ? 44 : 48, height: expandedLayout ? 44 : 48)
                        .background(Color.deltsAccent.opacity(0.88), in: Circle())
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.16), lineWidth: 0.5)
                        }
                }

                heroMetrics

                NavigationLink {
                    PlanBuilderView()
                } label: {
                    Label {
                        Text("Start Workout")
                            .lineLimit(1)
                            .minimumScaleFactor(0.86)
                    } icon: {
                        Image(systemName: "play.fill")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: expandedLayout ? 58 : 54)
                    .padding(.horizontal, 18)
                    .background(Color.deltsAccent, in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.18), lineWidth: 0.5)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(expandedLayout ? 20 : 18)
        }
        .frame(minHeight: heroHeight)
        .accessibilityElement(children: .contain)
    }

    private var heroMetrics: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                HomeHeroMetric(value: "\(recommendedExerciseCount)", label: "Exercises", systemImage: "list.bullet")
                HomeHeroMetric(value: "\(profile?.workoutDurationMinutes ?? 60)", label: "Minutes", systemImage: "timer")
                HomeHeroMetric(value: profile?.workoutSplit.shortTitle ?? "PPL", label: "Split", systemImage: "square.grid.2x2")
            }

            VStack(alignment: .leading, spacing: 8) {
                HomeHeroMetric(value: "\(recommendedExerciseCount)", label: "Exercises", systemImage: "list.bullet")
                HomeHeroMetric(value: "\(profile?.workoutDurationMinutes ?? 60)", label: "Minutes", systemImage: "timer")
                HomeHeroMetric(value: profile?.workoutSplit.shortTitle ?? "PPL", label: "Split", systemImage: "square.grid.2x2")
            }
        }
    }

    private var glanceStats: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeltsSectionHeader(title: "At a Glance")

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 0) {
                    HomeInlineStat(title: "Goal", value: profile?.mainGoal.shortTitle ?? "Muscle", systemImage: "target", tint: .deltsAccent)
                    HomeStatSeparator(axis: .vertical)
                    HomeInlineStat(title: "Weekly", value: "\(profile?.workoutFrequencyPerWeek ?? 4)x", systemImage: "calendar", tint: .deltsSecondaryAccent)
                    HomeStatSeparator(axis: .vertical)
                    HomeInlineStat(title: "History", value: "\(completedWorkouts.count)", systemImage: "checkmark.seal.fill", tint: .deltsAccent)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HomeInlineStat(title: "Goal", value: profile?.mainGoal.shortTitle ?? "Muscle", systemImage: "target", tint: .deltsAccent)
                    HomeStatSeparator(axis: .horizontal)
                    HomeInlineStat(title: "Weekly", value: "\(profile?.workoutFrequencyPerWeek ?? 4)x", systemImage: "calendar", tint: .deltsSecondaryAccent)
                    HomeStatSeparator(axis: .horizontal)
                    HomeInlineStat(title: "History", value: "\(completedWorkouts.count)", systemImage: "checkmark.seal.fill", tint: .deltsAccent)
                }
            }
            .padding(.horizontal, expandedLayout ? 12 : 14)
            .padding(.vertical, expandedLayout ? 12 : 14)
            .background(Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            DeltsSectionHeader(title: "Quick Actions")

            LazyVGrid(columns: actionColumns, alignment: .leading, spacing: 10) {
                NavigationLink {
                    PlanBuilderView()
                } label: {
                    HomeActionButton(title: "Build", systemImage: "calendar.badge.plus", tint: .deltsAccent)
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
                    HomeActionButton(title: "Gear", systemImage: "dumbbell.fill", tint: .deltsSecondaryAccent)
                }
                .buttonStyle(.plain)

                if let latest = completedWorkouts.first {
                    NavigationLink {
                        CompletedWorkoutDetailView(workout: latest)
                    } label: {
                        HomeActionButton(title: "History", systemImage: "clock.arrow.circlepath", tint: .deltsSecondaryAccent)
                    }
                    .buttonStyle(.plain)
                } else {
                    HomeActionButton(title: "History", systemImage: "clock.arrow.circlepath", tint: .deltsMutedText, isEnabled: false)
                        .accessibilityLabel("History unavailable")
                }
            }
        }
    }

    private var focusSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Label("Current focus", systemImage: "target")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)

                Spacer(minLength: 8)

                Text(profile?.experienceLevel.title ?? "Intermediate")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.deltsAccent.opacity(0.11), in: Capsule())
            }

            Text(focusText)
                .font(.subheadline)
                .foregroundStyle(Color.deltsMutedText)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    HomeFocusPill(title: "Split", value: profile?.workoutSplit.title ?? "PPL", systemImage: "square.grid.2x2")
                    HomeFocusPill(title: "Duration", value: "\(profile?.workoutDurationMinutes ?? 60)m", systemImage: "timer")
                }

                VStack(alignment: .leading, spacing: 10) {
                    HomeFocusPill(title: "Split", value: profile?.workoutSplit.title ?? "PPL", systemImage: "square.grid.2x2")
                    HomeFocusPill(title: "Duration", value: "\(profile?.workoutDurationMinutes ?? 60)m", systemImage: "timer")
                }
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var recentWorkouts: some View {
        if !completedWorkouts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                DeltsSectionHeader(title: "Recent Workouts", detail: "Last 3")

                VStack(spacing: 0) {
                    ForEach(recentWorkoutPreview) { workout in
                        NavigationLink {
                            CompletedWorkoutDetailView(workout: workout)
                        } label: {
                            HomeRecentWorkoutRow(workout: workout)
                        }
                        .buttonStyle(.plain)

                        if workout.id != recentWorkoutPreview.last?.id {
                            HomeStatSeparator(axis: .horizontal)
                                .padding(.leading, 50)
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

    private var expandedLayout: Bool {
        switch dynamicTypeSize {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }

    private var heroHeight: CGFloat {
        expandedLayout ? 420 : 304
    }

    private var horizontalPadding: CGFloat {
        expandedLayout ? 18 : 20
    }

    private var actionColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: expandedLayout ? 148 : 132),
                spacing: 10,
                alignment: .top
            )
        ]
    }

    private var recentWorkoutPreview: [CompletedWorkout] {
        Array(completedWorkouts.prefix(3))
    }
}

private struct HomeHeroMetric: View {
    let value: String
    let label: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsOnAccent.opacity(0.82))

            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.28), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        }
    }
}

private struct HomeInlineStat: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
    }
}

private struct HomeActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    var isEnabled = true

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isEnabled ? tint : Color.deltsMutedText)
                .frame(width: 34, height: 34)
                .background((isEnabled ? tint : Color.deltsMutedText).opacity(0.12), in: Circle())

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isEnabled ? Color.deltsCharcoal : Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsMutedText.opacity(isEnabled ? 0.72 : 0))
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background((isEnabled ? tint : Color.deltsPanel).opacity(isEnabled ? 0.08 : 0.12), in: Capsule())
        .overlay {
            Capsule()
                .stroke((isEnabled ? tint : Color.deltsHairline).opacity(isEnabled ? 0.28 : 0.22), lineWidth: 0.5)
        }
        .contentShape(Capsule())
        .opacity(isEnabled ? 1 : 0.62)
    }
}

private struct HomeFocusPill: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            HStack(spacing: 5) {
                Text(title)
                    .foregroundStyle(Color.deltsMutedText)
                Text(value)
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.deltsSecondaryAccent)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.deltsPanel.opacity(0.14), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
        }
    }
}

private struct HomeRecentWorkoutRow: View {
    let workout: CompletedWorkout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 38, height: 38)
                .background(Color.deltsSecondaryAccent.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)

                Text("\(workout.exerciseLogs.count) exercises")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 4) {
                Text(workout.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.deltsMutedText.opacity(0.72))
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private struct HomeStatSeparator: View {
    enum Axis {
        case horizontal
        case vertical
    }

    let axis: Axis

    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.30))
            .frame(
                width: axis == .vertical ? 0.5 : nil,
                height: axis == .horizontal ? 0.5 : 46
            )
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

private extension WorkoutSplit {
    var shortTitle: String {
        switch self {
        case .fullBody: return "Full"
        case .pushPullLegs: return "PPL"
        case .upperLower: return "Upper"
        case .broSplit: return "Split"
        case .custom: return "Custom"
        }
    }
}
