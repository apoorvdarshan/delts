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
                    quickActions
                    focusSummary
                }
                .padding(20)
            }
            .deltsScreen()
            .navigationTitle("delts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready, \(profile?.name.isEmpty == false ? profile?.name ?? "Athlete" : "Athlete")")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text("AI workout planning, equipment-first training, and logged progress.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayWorkout: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Today's recommendation")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.deltsElectricBlue)
                            .textCase(.uppercase)
                        Text(recommendedTitle)
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundStyle(Color.deltsInferno)
                }

                AnimatedExerciseVisual(muscleGroup: recommendedMuscle, height: 160)

                HStack(spacing: 8) {
                    MetricPill(title: "Goal", value: profile?.mainGoal.title ?? "Muscle Gain", systemImage: "target")
                    MetricPill(title: "Duration", value: "\(profile?.workoutDurationMinutes ?? 60)m", systemImage: "clock", tint: .deltsInferno)
                }
            }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick start")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                NavigationLink {
                    PlanBuilderView()
                } label: {
                    quickActionTile("Build Workout", systemImage: "sparkles", tint: .deltsElectricBlue)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EquipmentScanComingSoonView()
                } label: {
                    quickActionTile("Scan Equipment", systemImage: "camera.viewfinder", tint: .deltsInferno)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EquipmentManualSelectionView()
                } label: {
                    quickActionTile("Select Equipment", systemImage: "square.grid.2x2.fill", tint: .deltsElectricBlue)
                }
                .buttonStyle(.plain)

                if let latest = completedWorkouts.first {
                    NavigationLink {
                        CompletedWorkoutDetailView(workout: latest)
                    } label: {
                        quickActionTile("Continue Last", systemImage: "play.fill", tint: .deltsInferno)
                    }
                    .buttonStyle(.plain)
                } else {
                    quickActionTile("Continue Last", systemImage: "play.slash.fill", tint: .white.opacity(0.5))
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

                HStack(spacing: 8) {
                    MetricPill(title: "Split", value: profile?.workoutSplit.title ?? "PPL", systemImage: "calendar")
                    MetricPill(title: "Weekly", value: "\(profile?.workoutFrequencyPerWeek ?? 4)x", systemImage: "bolt.fill", tint: .deltsInferno)
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

    private var focusText: String {
        let focus = profile?.selectedBodyFocus.map(\.title).sorted().joined(separator: ", ")
        guard let focus, !focus.isEmpty else {
            return "Set body focus and equipment in Profile to sharpen workout recommendations."
        }
        return "\(profile?.mainGoal.title ?? "Muscle Gain") with emphasis on \(focus)."
    }

    private func quickActionTile(_ title: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.14), in: Circle())
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

