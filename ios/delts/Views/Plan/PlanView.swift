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
    @StateObject private var viewModel = PlanViewModel()
    @State private var generatedPlan: WorkoutPlan?
    @State private var didSyncProfile = false

    private let durationOptions = [30, 45, 60, 90]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                coachHero
                generatorControls
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 110)
        }
        .deltsScreen()
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.large)
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
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                AnimatedExerciseVisual(
                    muscleGroup: viewModel.selectedMuscleGroup,
                    equipment: viewModel.selectedEquipment.first,
                    height: 232
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                LinearGradient(
                    colors: [.black.opacity(0.03), .black.opacity(0.16), .black.opacity(0.72)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(GeminiConfig.hasAPIKey ? "AI planner ready" : "Offline planner")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.76))
                        .textCase(.uppercase)
                    Text("\(viewModel.selectedMuscleGroup.title) Day")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                    Text("\(viewModel.selectedDuration) min - \(viewModel.selectedGoal.title)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }
                .padding(18)
            }

            HStack(spacing: 0) {
                PlanInlineMetric(title: "Level", value: viewModel.selectedExperience.title)
                Divider().frame(height: 42)
                PlanInlineMetric(title: "Gear", value: "\(viewModel.selectedEquipment.count)")
                Divider().frame(height: 42)
                PlanInlineMetric(title: "Mode", value: GeminiConfig.hasAPIKey ? "AI" : "Local")
            }
        }
    }

    private var generatorControls: some View {
        VStack(alignment: .leading, spacing: 0) {
            planControl("Muscle group") {
                MuscleGroupPicker(selection: $viewModel.selectedMuscleGroup)
            }

            Divider()

            planControl("Goal") {
                PlanChoiceRail(
                    options: FitnessGoal.planCases,
                    selection: $viewModel.selectedGoal,
                    title: { $0.title }
                )
            }

            Divider()

            planControl("Experience") {
                PlanChoiceRail(
                    options: ExperienceLevel.allCases,
                    selection: $viewModel.selectedExperience,
                    title: { $0.title }
                )
            }

            Divider()

            planControl("Duration") {
                PlanChoiceRail(
                    options: durationOptions,
                    selection: $viewModel.selectedDuration,
                    title: { "\($0) min" }
                )
            }

            Divider()

            planControl("Equipment", detail: "\(viewModel.selectedEquipment.count) selected") {
                EquipmentGrid(selection: $viewModel.selectedEquipment)
            }
        }
    }

    private var generateBar: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: "Generate Workout",
                systemImage: GeminiConfig.hasAPIKey ? "sparkles" : "bolt.fill",
                isLoading: viewModel.isGenerating
            ) {
                Task {
                    generatedPlan = await viewModel.generateWorkout(profile: profiles.first)
                }
            }

            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    private func planControl<Content: View>(
        _ title: String,
        detail: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if let detail {
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 10)

            content()
        }
        .padding(.vertical, 18)
    }
}

private struct PlanChoiceRail<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
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
                        Text(title(option))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.deltsOnAccent : Color.deltsCharcoal)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
                            .frame(height: 40)
                            .background(
                                isSelected ? Color.deltsAccent : Color.deltsPanel.opacity(0.48),
                                in: Capsule()
                            )
                            .overlay {
                                Capsule()
                                    .stroke(Color.deltsHairline.opacity(isSelected ? 0.2 : 0.46), lineWidth: 0.5)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                }
            }
            .padding(.horizontal, 1)
        }
    }
}

private struct PlanInlineMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

private struct ExerciseStartRoute: Identifiable, Hashable {
    let id = UUID()
    let index: Int
}

struct WorkoutPlanView: View {
    let plan: WorkoutPlan
    @State private var startRoute: ExerciseStartRoute?

    private var exercises: [WorkoutExercise] {
        plan.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                planHero

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCard(exercise: exercise) {
                            startRoute = ExerciseStartRoute(index: index)
                        }
                        if exercise.id != exercises.last?.id {
                            Divider()
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
            .background(.bar)
        }
        .navigationDestination(item: $startRoute) { route in
            ActiveWorkoutView(plan: plan, startIndex: route.index)
        }
    }

    private var planHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .topLeading) {
                AnimatedExerciseVisual(
                    muscleGroup: plan.muscleGroup,
                    height: 236
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                Label(plan.generatedByAI ? "AI generated" : "Offline generated", systemImage: plan.generatedByAI ? "sparkles" : "bolt.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(.black.opacity(0.50), in: Capsule())
                    .padding(14)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(plan.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)

                Text(plan.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 0) {
                PlanInlineMetric(title: "Exercises", value: "\(exercises.count)")
                Divider().frame(height: 42)
                PlanInlineMetric(title: "Duration", value: "\(plan.durationMinutes)m")
                Divider().frame(height: 42)
                PlanInlineMetric(title: "Goal", value: plan.goal.title)
            }

            Divider()
        }
    }
}
