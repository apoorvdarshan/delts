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
                VStack(alignment: .leading, spacing: 22) {
                    header
                    coachHero
                    generatorControls
                    generateButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)
            }
            .deltsScreen()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $generatedPlan) { plan in
                WorkoutPlanView(plan: plan)
            }
        .onAppear {
            guard !didSyncProfile else { return }
            viewModel.syncDefaults(from: profiles.first)
            didSyncProfile = true
        }
    }

    private var header: some View {
        DeltsHeader(
            eyebrow: "Workout Planner",
            title: "Build Your Best Session",
            subtitle: GeminiConfig.hasAPIKey ? "Gemini AI is enabled. Local fallback stays ready." : "Offline generator active. Add a local Gemini key for AI plans.",
            trailingSystemImage: GeminiConfig.hasAPIKey ? "sparkles" : "bolt.fill"
        )
    }

    private var coachHero: some View {
        GlassCard(padding: 0, cornerRadius: 24) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Plan")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                    Text("\(viewModel.selectedMuscleGroup.title) Day")
                        .font(.title.weight(.black))
                        .fontDesign(.rounded)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("\(viewModel.selectedDuration) min - \(viewModel.selectedGoal.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        smallStat("Level", viewModel.selectedExperience.title, .deltsElectricBlue)
                        smallStat("Gear", "\(viewModel.selectedEquipment.count)", .deltsInferno)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)

                DoodleCoachIllustration(tint: Color.deltsPurple)
                    .frame(width: 92, height: 116)
                    .padding(.trailing, 16)
            }
            .background(Color.deltsPurple.opacity(0.08))
        }
    }

    private var generatorControls: some View {
        VStack(alignment: .leading, spacing: 18) {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    label("Muscle group")
                    MuscleGroupPicker(selection: $viewModel.selectedMuscleGroup)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    label("Goal")
                    Picker("Goal", selection: $viewModel.selectedGoal) {
                        ForEach(FitnessGoal.planCases) { goal in
                            Text(goal.title).tag(goal)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    label("Experience")
                    Picker("Experience", selection: $viewModel.selectedExperience) {
                        ForEach(ExperienceLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    label("Duration")
                    Picker("Duration", selection: $viewModel.selectedDuration) {
                        ForEach(durationOptions, id: \.self) { duration in
                            Text("\(duration) min").tag(duration)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        label("Equipment available")
                        Spacer()
                        Text("\(viewModel.selectedEquipment.count) selected")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    EquipmentGrid(selection: $viewModel.selectedEquipment)
                }
            }
        }
    }

    private var generateButton: some View {
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
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func smallStat(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.deltsMutedText)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.deltsInk.opacity(0.5), lineWidth: 1)
        )
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
            VStack(alignment: .leading, spacing: 20) {
                GlassCard(padding: 0, cornerRadius: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        AnimatedExerciseVisual(
                            muscleGroup: plan.muscleGroup,
                            height: 180
                        )

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(plan.generatedByAI ? "AI generated" : "Offline generated")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(plan.generatedByAI ? Color.deltsElectricBlue : Color.deltsInferno)
                                    .textCase(.uppercase)
                                Text(plan.title)
                                    .font(.largeTitle.weight(.black))
                                    .fontDesign(.rounded)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.72)
                            }
                            Spacer()
                            Image(systemName: plan.generatedByAI ? "sparkles" : "bolt.fill")
                                .font(.title2)
                                .foregroundStyle(plan.generatedByAI ? Color.deltsElectricBlue : Color.deltsInferno)
                        }
                        .padding(.horizontal, 18)

                        Text(plan.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 18)

                        HStack(spacing: 8) {
                            MetricPill(title: "Exercises", value: "\(exercises.count)", systemImage: "list.number")
                            MetricPill(title: "Duration", value: "\(plan.durationMinutes)m", systemImage: "clock", tint: .deltsInferno)
                        }
                        .padding(.horizontal, 18)

                        PrimaryButton(title: "Start Workout", systemImage: "play.fill") {
                            startRoute = ExerciseStartRoute(index: 0)
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Exercises")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)

                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCard(exercise: exercise) {
                            startRoute = ExerciseStartRoute(index: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $startRoute) { route in
            ActiveWorkoutView(plan: plan, startIndex: route.index)
        }
    }
}
