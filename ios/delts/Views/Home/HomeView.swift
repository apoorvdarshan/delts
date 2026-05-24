import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @StateObject private var viewModel = PlanViewModel()
    @State private var generatedPlan: WorkoutPlan?
    @State private var reviewPlan: WorkoutPlan?
    @State private var equipmentMode: StartEquipmentMode = .profile
    @State private var selectedProfileEquipment: Set<Equipment> = []
    @State private var didSyncProfile = false

    private let durationOptions = [30, 45, 60, 90]

    private var profile: UserProfile? {
        profiles.first
    }

    private var displayedEquipment: Set<Equipment> {
        switch equipmentMode {
        case .profile:
            return selectedProfileEquipment
        case .bodyweight:
            return [.bodyweight]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    startHeader
                    startHero
                    equipmentStep
                    muscleStep
                    levelStep
                    planPreview
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 122)
            }
            .deltsScreen()
            .navigationTitle("Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                startBar
            }
            .navigationDestination(item: $reviewPlan) { plan in
                WorkoutPlanView(plan: plan)
            }
            .onAppear(perform: syncProfileOnce)
        }
    }

    private var startHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("delts")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
                .textCase(.uppercase)

            Text("Start")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(Color.deltsCharcoal)

            Text("\(viewModel.selectedMuscleGroup.title) - \(viewModel.selectedExperience.title) - \(equipmentSummary)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startHero: some View {
        ZStack(alignment: .bottomLeading) {
            AnimatedExerciseVisual(
                muscleGroup: viewModel.selectedMuscleGroup,
                equipment: displayedEquipment.first,
                height: 248
            )
            .saturation(0.74)
            .contrast(1.06)
            .brightness(-0.07)
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            LinearGradient(
                colors: [
                    Color.deltsBackground.opacity(0.10),
                    .black.opacity(0.26),
                    .black.opacity(0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 16) {
                Label("Guided workout", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.86))

                Spacer(minLength: 44)

                VStack(alignment: .leading, spacing: 9) {
                    Text("\(viewModel.selectedMuscleGroup.title) workout")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text(heroSubtitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(2)
                }

                StartProgressStrip(
                    muscle: viewModel.selectedMuscleGroup,
                    level: viewModel.selectedExperience,
                    equipmentCount: displayedEquipment.count,
                    duration: viewModel.selectedDuration
                )
            }
            .padding(20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
        }
    }

    private var heroSubtitle: String {
        let name = profile?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = (name?.isEmpty == false ? name : "Athlete") ?? "Athlete"
        return "\(displayName) - \(viewModel.selectedExperience.title) - \(viewModel.selectedDuration) min"
    }

    private var equipmentSummary: String {
        displayedEquipment.count == 1 ? "1 item" : "\(displayedEquipment.count) items"
    }

    private var equipmentStep: some View {
        StartSection(
            index: "01",
            title: "Equipment",
            subtitle: "Use profile gear, pick from saved gear, or skip to bodyweight."
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    StartOptionButton(
                        title: "Profile gear",
                        systemImage: "dumbbell.fill",
                        isSelected: equipmentMode == .profile
                    ) {
                        equipmentMode = .profile
                        viewModel.selectedEquipment = selectedProfileEquipment
                    }

                    StartOptionButton(
                        title: "Skip",
                        systemImage: "figure.cooldown",
                        isSelected: equipmentMode == .bodyweight
                    ) {
                        equipmentMode = .bodyweight
                        viewModel.selectedEquipment = [.bodyweight]
                    }
                }

                if profileEquipment.isEmpty {
                    Text("No saved equipment yet. Add it from Profile when you want machine-specific plans.")
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 10)], spacing: 10) {
                        ForEach(profileEquipment) { equipment in
                            StartEquipmentChip(
                                equipment: equipment,
                                isSelected: selectedProfileEquipment.contains(equipment) && equipmentMode == .profile
                            ) {
                                equipmentMode = .profile
                                if selectedProfileEquipment.contains(equipment) {
                                    selectedProfileEquipment.remove(equipment)
                                } else {
                                    selectedProfileEquipment.insert(equipment)
                                }
                                viewModel.selectedEquipment = selectedProfileEquipment
                            }
                        }
                    }
                }
            }
        }
    }

    private var profileEquipment: [Equipment] {
        guard let profile else { return [] }
        return Equipment.allCases.filter { profile.availableEquipment.contains($0) }
    }

    private var muscleStep: some View {
        StartSection(
            index: "02",
            title: "Body Part",
            subtitle: "Pick what you are training now. The library previews move between exercise frames."
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 14)], spacing: 14) {
                ForEach(MuscleGroup.allCases) { group in
                    StartMuscleCard(
                        group: group,
                        isSelected: viewModel.selectedMuscleGroup == group
                    ) {
                        viewModel.selectedMuscleGroup = group
                        generatedPlan = nil
                    }
                }
            }
        }
    }

    private var levelStep: some View {
        StartSection(
            index: "03",
            title: "Level",
            subtitle: "Choose intensity, duration, and training bias."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                StartHorizontalRail {
                    ForEach(ExperienceLevel.allCases) { level in
                        StartOptionButton(
                            title: level.title,
                            systemImage: planExperienceIcon(level),
                            isSelected: viewModel.selectedExperience == level
                        ) {
                            viewModel.selectedExperience = level
                            generatedPlan = nil
                        }
                    }
                }

                StartHorizontalRail {
                    ForEach(FitnessGoal.planCases) { goal in
                        StartOptionButton(
                            title: goal.title,
                            systemImage: planGoalIcon(goal),
                            isSelected: viewModel.selectedGoal == goal
                        ) {
                            viewModel.selectedGoal = goal
                            generatedPlan = nil
                        }
                    }
                }

                StartHorizontalRail {
                    ForEach(durationOptions, id: \.self) { duration in
                        StartOptionButton(
                            title: "\(duration) min",
                            systemImage: planDurationIcon(duration),
                            isSelected: viewModel.selectedDuration == duration
                        ) {
                            viewModel.selectedDuration = duration
                            generatedPlan = nil
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var planPreview: some View {
        if let generatedPlan {
            StartSection(
                index: "04",
                title: "Workout",
                subtitle: "Review the session, then log sets, reps, weight, skips, and rest inside Active Workout."
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(generatedPlan.exercises.sorted { $0.orderIndex < $1.orderIndex }.prefix(5)) { exercise in
                        StartExercisePreviewRow(exercise: exercise)
                    }

                    HStack(spacing: 10) {
                        Button {
                            reviewPlan = generatedPlan
                        } label: {
                            Label("Review All", systemImage: "list.clipboard.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.deltsCharcoal)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.deltsPanel.opacity(0.28), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            ActiveWorkoutView(plan: generatedPlan)
                        } label: {
                            Label("Start", systemImage: "play.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.deltsOnAccent)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.deltsAccent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var startBar: some View {
        VStack(spacing: 8) {
            PrimaryButton(
                title: viewModel.isGenerating ? "Building Workout" : "Show Workouts",
                systemImage: "play.fill",
                isLoading: viewModel.isGenerating
            ) {
                Task {
                    if equipmentMode == .bodyweight {
                        viewModel.selectedEquipment = [.bodyweight]
                    } else {
                        viewModel.selectedEquipment = selectedProfileEquipment
                    }
                    generatedPlan = await viewModel.generateWorkout(profile: profile)
                }
            }

            if let statusText {
                Text(statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.deltsMutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private var statusText: String? {
        if viewModel.isGenerating {
            return "Using \(displayedEquipment.count) equipment option\(displayedEquipment.count == 1 ? "" : "s") from this flow."
        }
        return viewModel.statusMessage
    }

    private func syncProfileOnce() {
        guard !didSyncProfile else { return }
        didSyncProfile = true
        viewModel.syncDefaults(from: profile)
        selectedProfileEquipment = profile?.availableEquipment ?? []
        equipmentMode = selectedProfileEquipment.isEmpty ? .bodyweight : .profile
        viewModel.selectedEquipment = displayedEquipment
    }
}

private enum StartEquipmentMode {
    case profile
    case bodyweight
}

private struct StartSection<Content: View>: View {
    let index: String
    let title: String
    let subtitle: String
    let content: Content

    init(index: String, title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.index = index
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(index)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.deltsAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.deltsCharcoal)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.deltsMutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
    }
}

private struct StartProgressStrip: View {
    let muscle: MuscleGroup
    let level: ExperienceLevel
    let equipmentCount: Int
    let duration: Int

    var body: some View {
        HStack(spacing: 0) {
            StartHeroMetric(title: "Focus", value: muscle.title, systemImage: muscle.icon)
            StartHeroDivider()
            StartHeroMetric(title: "Level", value: level.title, systemImage: planExperienceIcon(level))
            StartHeroDivider()
            StartHeroMetric(title: "Gear", value: "\(equipmentCount)", systemImage: "dumbbell.fill")
            StartHeroDivider()
            StartHeroMetric(title: "Time", value: "\(duration)", systemImage: "timer")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.black.opacity(0.36), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct StartHeroMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.deltsAccent)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct StartHeroDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.16))
            .frame(width: 0.5, height: 42)
            .padding(.horizontal, 8)
    }
}

private struct StartOptionButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal)
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.22), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.deltsHairline.opacity(isSelected ? 0.18 : 0.30), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StartHorizontalRail<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                content
            }
            .padding(.horizontal, 1)
        }
    }
}

private struct StartEquipmentChip: View {
    let equipment: Equipment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: equipment.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsSecondaryAccent)

                Text(equipment.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsHairline)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(isSelected ? Color.deltsAccent.opacity(0.11) : Color.deltsPanel.opacity(0.16), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? Color.deltsAccent.opacity(0.36) : Color.deltsHairline.opacity(0.24), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StartMuscleCard: View {
    let group: MuscleGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                AnimatedExerciseVisual(muscleGroup: group, height: 126)

                HStack(spacing: 8) {
                    Image(systemName: group.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.deltsAccent)

                    Text(group.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.deltsCharcoal)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    Image(systemName: isSelected ? "checkmark" : "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsMutedText)
                }
            }
            .padding(10)
            .background(isSelected ? Color.deltsAccent.opacity(0.10) : Color.deltsPanel.opacity(0.18), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(isSelected ? Color.deltsAccent.opacity(0.42) : Color.deltsHairline.opacity(0.24), lineWidth: 0.75)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StartExercisePreviewRow: View {
    let exercise: WorkoutExercise

    var body: some View {
        HStack(spacing: 14) {
            AnimatedExerciseVisual(
                muscleGroup: exercise.targetMuscle,
                exerciseName: exercise.name,
                equipment: exercise.equipment,
                height: 82,
                fillsWidth: false
            )
            .frame(width: 82, height: 82)

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)

                Text("\(exercise.sets) sets - \(exercise.reps) reps - \(exercise.restDisplay)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.deltsMutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
