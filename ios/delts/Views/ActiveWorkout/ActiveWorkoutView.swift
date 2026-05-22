import SwiftData
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ActiveWorkoutViewModel

    init(plan: WorkoutPlan, startIndex: Int = 0) {
        _viewModel = StateObject(wrappedValue: ActiveWorkoutViewModel(plan: plan, startIndex: startIndex))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let exercise = viewModel.currentExercise {
                    AnimatedExerciseVisual(
                        muscleGroup: exercise.targetMuscle,
                        exerciseName: exercise.name,
                        equipment: exercise.equipment,
                        height: 210
                    )

                    exerciseDetails(exercise)
                    setChecklist(for: exercise)
                    restTimerPlaceholder(exercise)
                    footerControls
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .deltsScreen()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        GlassCard(padding: 16, cornerRadius: 24) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Active Workout")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.deltsMutedText)
                        .textCase(.uppercase)
                    Text(viewModel.plan.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text("Exercise \(viewModel.progressText)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                DeltsProgressRing(progress: progress, label: "Done", tint: .deltsElectricBlue)
            }

            ProgressView(value: progress)
                .tint(Color.deltsElectricBlue)
                .padding(.top, 8)
        }
    }

    private func exerciseDetails(_ exercise: WorkoutExercise) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(exercise.name)
                    .font(.title.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text("\(exercise.targetMuscle.title) - \(exercise.equipment.title)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.64))

                HStack(spacing: 8) {
                    MetricPill(title: "Sets", value: "\(exercise.sets)", systemImage: "number")
                    MetricPill(title: "Reps", value: exercise.reps, systemImage: "repeat", tint: .deltsInferno)
                    MetricPill(title: "Rest", value: exercise.restDisplay, systemImage: "timer", tint: .white.opacity(0.78))
                }

                Text(exercise.formTip)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func setChecklist(for exercise: WorkoutExercise) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sets")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                ForEach(0..<max(exercise.sets, 1), id: \.self) { setIndex in
                    HStack(spacing: 12) {
                        Button {
                            viewModel.toggleSet(setIndex)
                        } label: {
                            Image(systemName: isSetComplete(setIndex) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSetComplete(setIndex) ? Color.deltsElectricBlue : Color.white.opacity(0.45))
                        }
                        .buttonStyle(.plain)

                        Text("Set \(setIndex + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 58, alignment: .leading)

                        TextField("Weight", text: weightBinding(setIndex))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        TextField("Reps", text: repsBinding(setIndex))
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .frame(width: 78)
                    }
                }
            }
        }
    }

    private func restTimerPlaceholder(_ exercise: WorkoutExercise) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.deltsInferno)
                    .frame(width: 44, height: 44)
                    .background(Color.deltsInferno.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest timer")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(exercise.restSeconds) seconds placeholder")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
            }
        }
    }

    private var footerControls: some View {
        VStack(spacing: 12) {
            if viewModel.isLastExercise {
                PrimaryButton(title: "Finish Workout", systemImage: "checkmark.seal.fill") {
                    finishWorkout()
                }
            } else {
                PrimaryButton(title: "Next Exercise", systemImage: "arrow.right") {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        viewModel.nextExercise()
                    }
                }
            }

            Button {
                finishWorkout()
            } label: {
                Text("Save and exit")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(Color.deltsInferno)
                Text("No exercises found")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var progress: Double {
        guard !viewModel.exercises.isEmpty else { return 0 }
        return Double(viewModel.currentExerciseIndex + 1) / Double(viewModel.exercises.count)
    }

    private func isSetComplete(_ setIndex: Int) -> Bool {
        viewModel.completedSets[safe: viewModel.currentExerciseIndex]?[safe: setIndex] ?? false
    }

    private func weightBinding(_ setIndex: Int) -> Binding<String> {
        Binding {
            viewModel.weightInputs[safe: viewModel.currentExerciseIndex]?[safe: setIndex] ?? ""
        } set: { newValue in
            guard viewModel.weightInputs.indices.contains(viewModel.currentExerciseIndex),
                  viewModel.weightInputs[viewModel.currentExerciseIndex].indices.contains(setIndex)
            else { return }
            viewModel.weightInputs[viewModel.currentExerciseIndex][setIndex] = newValue
        }
    }

    private func repsBinding(_ setIndex: Int) -> Binding<String> {
        Binding {
            viewModel.repInputs[safe: viewModel.currentExerciseIndex]?[safe: setIndex] ?? ""
        } set: { newValue in
            guard viewModel.repInputs.indices.contains(viewModel.currentExerciseIndex),
                  viewModel.repInputs[viewModel.currentExerciseIndex].indices.contains(setIndex)
            else { return }
            viewModel.repInputs[viewModel.currentExerciseIndex][setIndex] = newValue
        }
    }

    private func finishWorkout() {
        let completed = viewModel.makeCompletedWorkout()
        modelContext.insert(completed)
        try? modelContext.save()
        dismiss()
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
