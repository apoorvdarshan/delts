import SwiftData
import SwiftUI

struct PlanView: View {
    var body: some View {
        NavigationStack {
            PlanBuilderView()
        }
    }
}

struct PlanBuilderView: View {
    @Query(sort: \UserProfile.updatedAt, order: .reverse) private var profiles: [UserProfile]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = PlanViewModel()
    @State private var generatedPlan: WorkoutPlan?
    @State private var didSyncProfile = false

    private var heroHeight: CGFloat {
        horizontalSizeClass == .compact ? 214 : 252
    }

    private var equipmentDetail: String {
        viewModel.selectedEquipment.isEmpty ? "Profile gear" : "\(viewModel.selectedEquipment.count) selected"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 21) {
                coachHero
                generatorControls
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .deltsScreen()
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            generateBar
        }
        .navigationDestination(item: $generatedPlan) { plan in
            WorkoutPlanView(plan: plan)
        }
        .onAppear {
            guard !didSyncProfile else { return }
            viewModel.syncDefaults(from: profiles.first)
            didSyncProfile = true
        }
    }

    private var coachHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                AnimatedExerciseVisual(
                    muscleGroup: viewModel.selectedMuscleGroup,
                    equipment: viewModel.selectedEquipment.first,
                    height: heroHeight
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.18), .black.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 0) {
                    PlanHeroBadge(
                        title: (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? "AI planner ready" : "Offline planner",
                        systemImage: (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? "sparkles" : "bolt.fill"
                    )

                    Spacer(minLength: 34)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(viewModel.selectedMuscleGroup.title) Day")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)

                        Label {
                            Text("\(viewModel.selectedDurationRange.title) - \(viewModel.selectedGoal.title)")
                                .lineLimit(1)
                                .minimumScaleFactor(0.76)
                        } icon: {
                            Image(systemName: planGoalIcon(viewModel.selectedGoal))
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.84))
                    }
                }
                .padding(18)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
            }

            PlanMetricStrip(metrics: [
                PlanMetric(title: "Level", value: viewModel.selectedExperience.title, systemImage: planExperienceIcon(viewModel.selectedExperience), tint: .deltsSecondaryAccent),
                PlanMetric(title: "Gear", value: viewModel.selectedEquipment.isEmpty ? "Profile" : "\(viewModel.selectedEquipment.count)", systemImage: "dumbbell.fill"),
                PlanMetric(title: "Mode", value: (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? "AI" : "Local", systemImage: (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? "sparkles" : "bolt.fill", tint: (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? .deltsAccent : .deltsWarning)
            ])
        }
    }

    private var generatorControls: some View {
        VStack(alignment: .leading, spacing: 0) {
            planControl(
                "Muscle group",
                systemImage: viewModel.selectedMuscleGroup.icon,
                detail: viewModel.selectedMuscleGroup.title
            ) {
                MuscleGroupPicker(selection: $viewModel.selectedMuscleGroup)
            }

            PlanControlDivider()

            planControl("Goal", systemImage: planGoalIcon(viewModel.selectedGoal), detail: viewModel.selectedGoal.title) {
                PlanChoiceRail(
                    options: FitnessGoal.planCases,
                    selection: $viewModel.selectedGoal,
                    systemImage: planGoalIcon,
                    title: { $0.title }
                )
            }

            PlanControlDivider()

            planControl(
                "Experience",
                systemImage: planExperienceIcon(viewModel.selectedExperience),
                detail: viewModel.selectedExperience.title
            ) {
                PlanChoiceRail(
                    options: ExperienceLevel.allCases,
                    selection: $viewModel.selectedExperience,
                    systemImage: planExperienceIcon,
                    title: { $0.title }
                )
            }

            PlanControlDivider()

            planControl(
                "Duration",
                systemImage: planDurationIcon(viewModel.selectedDurationRange.targetMinutes),
                detail: viewModel.selectedDurationRange.title
            ) {
                PlanChoiceRail(
                    options: WorkoutDurationRangeOption.options,
                    selection: $viewModel.selectedDurationRange,
                    systemImage: { planDurationIcon($0.targetMinutes) },
                    title: { $0.title }
                )
            }

            PlanControlDivider()

            planControl("Equipment", systemImage: "dumbbell.fill", detail: equipmentDetail) {
                PlanProfileEquipmentSummary(equipment: viewModel.selectedEquipment)
            }
        }
    }

    private var generateBar: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: viewModel.isGenerating ? "Building Workout" : "Generate Workout",
                systemImage: (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? "sparkles" : "bolt.fill",
                isLoading: viewModel.isGenerating
            ) {
                Task {
                    generatedPlan = await viewModel.generateWorkout(profile: profiles.first)
                }
            }

            if let generationStatusText {
                Label {
                    Text(generationStatusText)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: generationStatusIcon)
                }
                .font(.footnote.weight(.semibold))
                .foregroundStyle(generationStatusTint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(generationStatusTint.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.deltsHairline.opacity(0.28), lineWidth: 0.5)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .deltsBottomActionBackground()
    }

    private var generationStatusText: String? {
        if viewModel.isGenerating {
            return (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? "Building a tailored AI session." : "Building an offline session from your profile."
        }

        return viewModel.statusMessage
    }

    private var generationStatusIcon: String {
        if viewModel.isGenerating {
            return (GeminiConfig.isAIEnabled && PremiumStore.shared.isSubscribed) ? "sparkles" : "bolt.fill"
        }

        if viewModel.statusMessage?.localizedCaseInsensitiveContains("failed") == true {
            return "exclamationmark.triangle.fill"
        }

        return "checkmark"
    }

    private var generationStatusTint: Color {
        if viewModel.isGenerating {
            return Color.deltsAccent
        }

        if viewModel.statusMessage?.localizedCaseInsensitiveContains("failed") == true {
            return Color.deltsWarning
        }

        return Color.deltsSecondaryAccent
    }

    private func planControl<Content: View>(
        _ title: String,
        systemImage: String,
        detail: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PlanControlHeader(title: title, systemImage: systemImage, detail: detail)

            content()
        }
        .padding(.vertical, 16)
    }
}

private struct PlanChoiceRail<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let systemImage: (Option) -> String
    let title: (Option) -> String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selection

                    Button {
                        let animation: Animation? = reduceMotion ? nil : .snappy(duration: 0.18)
                        withAnimation(animation) {
                            selection = option
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: systemImage(option))
                                .font(.caption.weight(.bold))
                                .accessibilityHidden(true)

                            Text(title(option))
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal.opacity(0.88))
                        .padding(.horizontal, 13)
                        .frame(minHeight: 42)
                        .background(
                            isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.34),
                            in: Capsule()
                        )
                        .overlay {
                            Capsule()
                                .stroke(Color.deltsHairline.opacity(isSelected ? 0.22 : 0.42), lineWidth: 0.5)
                        }
                        .contentShape(Capsule())
                    }
                    .deltsPressable()
                    .accessibilityLabel(Text(title(option)))
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

private struct PlanControlHeader: View {
    let title: String
    let systemImage: String
    let detail: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 10) {
                leadingLabel
                Spacer(minLength: 12)
                detailLabel
            }

            VStack(alignment: .leading, spacing: 8) {
                leadingLabel
                detailLabel
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var leadingLabel: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.deltsSecondaryAccent)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.86)
        }
    }

    @ViewBuilder
    private var detailLabel: some View {
        if let detail {
            Text(detail)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .padding(.vertical, 5)
                .padding(.horizontal, 9)
                .background(Color.deltsPanel.opacity(0.26), in: Capsule())
        }
    }
}

private struct PlanControlDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.deltsHairline.opacity(0.32))
            .frame(height: 0.5)
    }
}

private struct PlanHeroBadge: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label {
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(.white.opacity(0.92))
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .background(.black.opacity(0.44), in: Capsule())
    }
}

private struct PlanMetric {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .deltsAccent
}

private struct PlanMetricStrip: View {
    let metrics: [PlanMetric]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(metrics.indices, id: \.self) { index in
                PlanMetricColumn(metric: metrics[index])

                if index < metrics.count - 1 {
                    Rectangle()
                        .fill(Color.deltsHairline.opacity(0.34))
                        .frame(width: 0.5, height: 54)
                        .padding(.horizontal, 2)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .deltsGlassSurface(cornerRadius: 18, tint: .deltsPanel, fallbackOpacity: 0.18)
    }
}

private struct PlanMetricColumn: View {
    let metric: PlanMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: metric.systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(metric.tint)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)

            Text(metric.value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.deltsCharcoal)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            Text(metric.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(.horizontal, 8)
    }
}

private struct PlanProfileEquipmentSummary: View {
    let equipment: Set<Equipment>

    private var selectedItems: [Equipment] {
        Equipment.allCases.filter { equipment.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Edit equipment from Profile only", systemImage: "person.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.deltsMutedText)

            if selectedItems.isEmpty {
                Text("No profile equipment selected. Plans will fall back to bodyweight choices.")
                    .font(.subheadline)
                    .foregroundStyle(Color.deltsMutedText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), spacing: 10)], alignment: .leading, spacing: 10) {
                    ForEach(selectedItems) { item in
                        Label(item.title, systemImage: item.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.deltsCharcoal)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                            .background(Color.deltsPanel.opacity(0.22), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.deltsHairline.opacity(0.30), lineWidth: 0.5)
                            }
                    }
                }
            }
        }
    }
}

private struct PlanEquipmentSection: Identifiable {
    let title: String
    let systemImage: String
    let items: [Equipment]

    var id: String { title }

    static let all: [PlanEquipmentSection] = [
        PlanEquipmentSection(
            title: "Free Weights",
            systemImage: "dumbbell.fill",
            items: [.dumbbells, .barbell, .bench]
        ),
        PlanEquipmentSection(
            title: "Machines",
            systemImage: "gearshape.2.fill",
            items: [
                .cableMachine,
                .smithMachine,
                .chestPress,
                .shoulderPress,
                .latPulldown,
                .rowMachine,
                .legPress,
                .legExtension,
                .legCurl
            ]
        ),
        PlanEquipmentSection(
            title: "Bodyweight & Cardio",
            systemImage: "figure.run",
            items: [.pullUpBar, .treadmill, .bodyweight]
        )
    ]
}

private struct PlanEquipmentToggle: View {
    let item: Equipment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsSecondaryAccent)
                    .frame(width: 31, height: 31)
                    .accessibilityHidden(true)

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.deltsCharcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.deltsAccent : Color.deltsHairline.opacity(0.72))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(
                isSelected ? Color.deltsAccent.opacity(0.11) : Color.deltsPanel.opacity(0.22),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isSelected ? Color.deltsAccent.opacity(0.52) : Color.deltsHairline.opacity(0.32),
                        lineWidth: 0.5
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .deltsPressable()
        .accessibilityLabel(Text(item.title))
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .equipmentSelectedTrait(isSelected)
    }
}

private extension View {
    @ViewBuilder
    func equipmentSelectedTrait(_ isSelected: Bool) -> some View {
        if isSelected {
            accessibilityAddTraits(.isSelected)
        } else {
            self
        }
    }
}

private struct ExerciseStartRoute: Identifiable, Hashable {
    let id = UUID()
    let index: Int
}

struct WorkoutPlanView: View {
    let plan: WorkoutPlan
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var startRoute: ExerciseStartRoute?

    private var exercises: [WorkoutExercise] {
        plan.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var heroHeight: CGFloat {
        horizontalSizeClass == .compact ? 214 : 252
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 21) {
                planHero

                VStack(alignment: .leading, spacing: 0) {
                    PlanControlHeader(
                        title: "Exercise order",
                        systemImage: "list.number",
                        detail: "\(exercises.count) moves"
                    )
                    .padding(.bottom, 8)

                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCard(exercise: exercise) {
                            startRoute = ExerciseStartRoute(index: index)
                        }
                        if exercise.id != exercises.last?.id {
                            PlanControlDivider()
                                .padding(.leading, 118)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 112)
        }
        .deltsScreen()
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Start Workout", systemImage: "play.fill") {
                startRoute = ExerciseStartRoute(index: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)
            .deltsBottomActionBackground()
        }
        .navigationDestination(item: $startRoute) { route in
            ActiveWorkoutView(plan: plan, startIndex: route.index)
        }
    }

    private var planHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                AnimatedExerciseVisual(
                    muscleGroup: plan.muscleGroup,
                    height: heroHeight
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.18), .black.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 0) {
                    PlanHeroBadge(
                        title: plan.generatedByAI ? "AI generated" : "Offline generated",
                        systemImage: plan.generatedByAI ? "sparkles" : "bolt.fill"
                    )

                    Spacer(minLength: 34)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.title)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .minimumScaleFactor(0.62)

                        Text(plan.summary)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.84))
                            .lineLimit(3)
                            .minimumScaleFactor(0.82)
                    }
                }
                .padding(18)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.deltsHairline.opacity(0.32), lineWidth: 0.5)
            }

            PlanMetricStrip(metrics: [
                PlanMetric(title: "Exercises", value: "\(exercises.count)", systemImage: "list.clipboard.fill", tint: .deltsSecondaryAccent),
                PlanMetric(title: "Duration", value: "\(plan.durationMinutes)m", systemImage: planDurationIcon(plan.durationMinutes)),
                PlanMetric(title: "Goal", value: plan.goal.title, systemImage: planGoalIcon(plan.goal), tint: .deltsAccent)
            ])
        }
    }
}

func planGoalIcon(_ goal: FitnessGoal) -> String {
    switch goal {
    case .muscleGain:
        return "figure.strengthtraining.traditional"
    case .endurance:
        return "lungs.fill"
    case .maxStrength:
        return "scalemass.fill"
    case .fatLoss:
        return "flame.fill"
    case .generalFitness:
        return "figure.highintensity.intervaltraining"
    case .athleticPerformance:
        return "bolt.fill"
    case .beginnerForm:
        return "figure.cooldown"
    }
}

func planExperienceIcon(_ experience: ExperienceLevel) -> String {
    switch experience {
    case .beginner:
        return "figure.cooldown"
    case .intermediate:
        return "chart.bar.fill"
    case .advanced:
        return "bolt.fill"
    }
}

func planDurationIcon(_ minutes: Int) -> String {
    switch minutes {
    case ..<45:
        return "timer"
    case 45..<60:
        return "clock"
    case 60..<90:
        return "clock.fill"
    default:
        return "hourglass"
    }
}
