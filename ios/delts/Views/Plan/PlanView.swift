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
                generatorControls
                generateButton
            }
            .padding(20)
        }
        .deltsScreen()
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Build your next session")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
            Text(GeminiConfig.hasAPIKey ? "Gemini AI is enabled. Local fallback stays ready." : "Offline generator active. Add a local Gemini key for AI plans.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
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
                            .foregroundStyle(.white.opacity(0.58))
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
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.62))
            .textCase(.uppercase)
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
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(plan.generatedByAI ? "AI generated" : "Offline generated")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(plan.generatedByAI ? Color.deltsElectricBlue : Color.deltsInferno)
                                    .textCase(.uppercase)
                                Text(plan.title)
                                    .font(.largeTitle.weight(.black))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.72)
                            }
                            Spacer()
                            Image(systemName: plan.generatedByAI ? "sparkles" : "bolt.fill")
                                .font(.title2)
                                .foregroundStyle(plan.generatedByAI ? Color.deltsElectricBlue : Color.deltsInferno)
                        }

                        Text(plan.summary)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            MetricPill(title: "Exercises", value: "\(exercises.count)", systemImage: "list.number")
                            MetricPill(title: "Duration", value: "\(plan.durationMinutes)m", systemImage: "clock", tint: .deltsInferno)
                        }

                        PrimaryButton(title: "Start Workout", systemImage: "play.fill") {
                            startRoute = ExerciseStartRoute(index: 0)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Exercises")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)

                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        ExerciseCard(exercise: exercise) {
                            startRoute = ExerciseStartRoute(index: index)
                        }
                    }
                }
            }
            .padding(20)
        }
        .deltsScreen()
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $startRoute) { route in
            ActiveWorkoutView(plan: plan, startIndex: route.index)
        }
    }
}
